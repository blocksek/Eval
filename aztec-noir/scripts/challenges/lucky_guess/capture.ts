import { parseArgs } from "node:util";

import { AztecAddress } from "@aztec/aztec.js/addresses";
import { getContractInstanceFromInstantiationParams } from "@aztec/stdlib/contract";
import { Fr } from "@aztec/aztec.js/fields";
import { randomBytes } from "@aztec/foundation/crypto/random";

import {
  LuckyGuessContract,
  LuckyGuessContractArtifact,
} from "../../../src/artifacts/LuckyGuess.ts";
import {
  BASE_PARSE_ARGS_OPTIONS,
  createWalletContext,
  fail,
  getTxWaitOptions,
  loadTestnetConfig,
  parseAddress,
  parseNonNegativeInteger,
  registerContractAllowAlreadyRegistered,
  resolveBaseOptions,
  setupFpcPayment,
} from "../../lib/shared.ts";

const FR_MODULUS =
  0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001n;

const RPS_ERROR = "Cheshire Cat";
const MAX_OFFSET = 20;

/**
 * Replicates what Fr.random() produces for a given RandomnessSingleton counter:
 *   getBytes(64) fills 64 bytes via (counter >> (i*8)) & 0xff.
 *   JS bitwise >> wraps shift amounts mod 32, so the 4-byte LE pattern repeats 16×.
 *   The buffer is interpreted as a big-endian 512-bit integer reduced mod Fr.MODULUS.
 */
function replicateFrRandom(counter: number): bigint {
  const buf = Buffer.alloc(64);
  for (let i = 0; i < 64; i++) {
    buf[i] = (counter >> (i * 8)) & 0xff;
  }
  return BigInt("0x" + buf.toString("hex")) % FR_MODULUS;
}

/**
 * Predicts the cat's move for a given counter.
 * Mirrors Noir: `fate.to_le_bytes()[0] % 3`.
 */
function predictCatMove(counter: number): number {
  const field = replicateFrRandom(counter);
  return Number(field & 0xffn) % 3;
}

/**
 * Computes 5 winning moves against the cat's predicted sequence.
 * RPS math: (player + 3 - cat) % 3 == 1  ⟹  player = (cat + 1) % 3.
 */
function computeWinningMoves(
  baseCounter: number,
): [number, number, number, number, number] {
  return Array.from({ length: 5 }, (_, i) => {
    const catMove = predictCatMove(baseCounter + i);
    return (catMove + 1) % 3;
  }) as [number, number, number, number, number];
}

function printHelp() {
  console.log(`Usage: yarn capture:lucky [options]

Options:
  --address <aztec-address>  LuckyGuess address (defaults to testnet.json)
  --seed <number>            SEED for deterministic randomness (default: random)
  --max-offset <number>      Inclusive max counter offset to try (default: ${MAX_OFFSET})
  --node-url <url>           Override the Aztec node URL
  --pxe-data-dir <path>      Override the PXE data directory
  --secret-key <hex>         Deployer secret key
  --fpc-address <addr>       SponsoredFPC address
  --fpc-salt <hex>           SponsoredFPC salt
  --deployment-salt <hex>    Salt for account derivation
  --fresh-pxe                Clear PXE data directory before starting
  --help                     Show this message`);
}

const args = parseArgs({
  options: {
    ...BASE_PARSE_ARGS_OPTIONS,
    address: { type: "string" },
    seed: { type: "string" },
    "max-offset": { type: "string" },
  },
});

if (args.values.help) {
  printHelp();
  process.exit(0);
}

// Setting SEED makes the PXE's RandomnessSingleton use a counter-based PRNG
// instead of cryptographic randomness. Since `unsafe { random() }` runs in
// the player's PXE, the Cheshire Cat's moves become fully deterministic.
const seed =
  (args.values.seed as string | undefined) ??
  String(Math.floor(Math.random() * 2 ** 32));
process.env.SEED = seed;
console.log(`SEED=${seed} — randomness is now deterministic.`);

const maxOffset = args.values["max-offset"]
  ? parseNonNegativeInteger("--max-offset", args.values["max-offset"])
  : MAX_OFFSET;

const opts = resolveBaseOptions(args);
const cfg = loadTestnetConfig();
const addressValue =
  (args.values.address as string | undefined) ?? cfg.challenges?.LuckyGuess;
if (!addressValue) {
  fail("Missing --address.");
}

const ctx = await createWalletContext(opts);
const wait = getTxWaitOptions();
const fee = await setupFpcPayment(ctx.wallet, opts);

const emitterAddress = cfg.flagEmitter
  ? parseAddress(cfg.flagEmitter)
  : fail("Missing flagEmitter in testnet.json.");

const challengeInstance = await getContractInstanceFromInstantiationParams(
  LuckyGuessContractArtifact,
  {
    salt: Fr.ZERO,
    constructorArgs: [emitterAddress],
    deployer: AztecAddress.ZERO,
  },
);
await registerContractAllowAlreadyRegistered(
  ctx.wallet,
  challengeInstance,
  LuckyGuessContractArtifact,
);

const contract = LuckyGuessContract.at(parseAddress(addressValue), ctx.wallet);
const sendOpts = { from: ctx.deployer, fee, wait } as any;

// Probe the PRNG counter, then predict the cat's moves and compute winning
// responses. The offset scan accounts for framework-internal randomBytes()
// calls between our probe and the oracle invocations.
console.log("Predicting the cat's moves from the PRNG state...");

for (let offset = 0; offset <= maxOffset; offset++) {
  const probe = randomBytes(4);
  const counter = probe.readUInt32LE(0) + 1 + offset;
  const moves = computeWinningMoves(counter);
  try {
    const { receipt } = await contract.methods
      .capture_flag(moves)
      .send(sendOpts);

    console.log(`\nCaptured! (counter=${counter}, offset=${offset})`);
    console.log(`caller=${ctx.deployer.toString()}`);
    console.log(`challenge=${addressValue}`);
    console.log(`txHash=${receipt.txHash.toString()}`);
    process.exit(0);
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (msg.includes(RPS_ERROR)) {
      process.stdout.write(".");
      continue;
    }
    throw e;
  }
}

fail(
  `Failed to capture — counter offset out of inclusive range 0..${maxOffset}.`,
);
