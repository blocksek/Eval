import { parseArgs } from "node:util";

import { AztecAddress } from "@aztec/aztec.js/addresses";
import { type CallIntent } from "@aztec/aztec.js/authorization";
import { getContractInstanceFromInstantiationParams } from "@aztec/stdlib/contract";
import { Fr } from "@aztec/aztec.js/fields";
import { getContractClassFromArtifact } from "@aztec/stdlib/contract";

import {
  SummonersDeckContract,
  SummonersDeckContractArtifact,
} from "../../../src/artifacts/SummonersDeck.ts";
import {
  SummonersDeckSolverContract,
  SummonersDeckSolverContractArtifact,
} from "../../../src/artifacts/SummonersDeckSolver.ts";
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

const U64_MASK = (1n << 64n) - 1n;

type Trio = [bigint, bigint, bigint];

function deriveTarget(classDigit: number, xorTail: bigint): bigint[] {
  let val = xorTail;
  const digits: number[] = [];
  for (let i = 0; i < 3; i++) {
    digits.push(Number(val % 10n));
    val /= 10n;
  }
  return [
    5n,
    BigInt(classDigit),
    BigInt(digits[2]),
    BigInt(digits[1]),
    BigInt(digits[0]),
    0n,
  ];
}

function getOptimalXorTail(classDigit: number): bigint {
  switch (classDigit) {
    case 1:
      return 234n;
    case 2:
      return 413n;
    case 3:
      return 412n;
    case 4:
      return 123n;
    default:
      throw new Error(`unexpected class_digit: ${classDigit}`);
  }
}

async function mineSolverSalt(
  deployer: AztecAddress,
  classDigit: number,
  maxAttempts: number,
): Promise<{ salt: Fr; address: AztecAddress; xorTail: bigint }> {
  const targetXorTail = getOptimalXorTail(classDigit);

  for (let i = 0; i < maxAttempts; i++) {
    const salt = Fr.random();
    const instance = await getContractInstanceFromInstantiationParams(
      SummonersDeckSolverContractArtifact,
      { salt, deployer },
    );
    const combined =
      (instance.address.toBigInt() & U64_MASK) ^ (salt.toBigInt() & U64_MASK);
    const xorTail = combined % 1000n;

    if (xorTail === targetXorTail) {
      if ((i + 1) % 100 === 0 || i === 0) {
        console.log(`  Found valid salt after ${i + 1} attempts`);
      }
      return { salt, address: instance.address, xorTail };
    }

    if ((i + 1) % 1000 === 0) {
      console.log(`  ${i + 1} attempts...`);
    }
  }
  throw new Error(
    `Could not mine a valid solver salt in ${maxAttempts} attempts`,
  );
}

function printHelp() {
  console.log(`Usage: yarn capture:summoners [options]

Options:
  --address <aztec-address>  SummonersDeck address (defaults to testnet.json)
  --max-attempts <n>         Max salt mining attempts (default: 100000)
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
    "max-attempts": { type: "string", default: "100000" },
  },
});

if (args.values.help) {
  printHelp();
  process.exit(0);
}

const maxAttemptsRaw = args.values["max-attempts"]!;
const maxAttempts = Number(maxAttemptsRaw);
if (!Number.isInteger(maxAttempts) || maxAttempts <= 0) {
  fail(
    `Invalid --max-attempts value: "${maxAttemptsRaw}". Must be a positive integer.`,
  );
}

const opts = resolveBaseOptions(args);
const cfg = loadTestnetConfig();
const addressValue =
  (args.values.address as string | undefined) ?? cfg.challenges?.SummonersDeck;
if (!addressValue) {
  fail("Missing --address.");
}

const ctx = await createWalletContext(opts);
const wait = getTxWaitOptions();
const fee = await setupFpcPayment(ctx.wallet, opts);
const sendOpts = { from: ctx.deployer, fee, wait } as any;

const challengeAddress = parseAddress(addressValue);
const emitterAddress = cfg.flagEmitter
  ? parseAddress(cfg.flagEmitter)
  : fail("Missing flagEmitter in testnet.json.");

// Register challenge contract with PXE (needed after fresh PXE or first run)
const challengeInstance = await getContractInstanceFromInstantiationParams(
  SummonersDeckContractArtifact,
  {
    salt: Fr.ZERO,
    constructorArgs: [emitterAddress],
    deployer: AztecAddress.ZERO,
  },
);
await registerContractAllowAlreadyRegistered(
  ctx.wallet,
  challengeInstance,
  SummonersDeckContractArtifact,
);

const challenge = SummonersDeckContract.at(challengeAddress, ctx.wallet);

// 1. Compute class_digit from the compiled artifact
const contractClass = await getContractClassFromArtifact(
  SummonersDeckSolverContractArtifact,
);
const classDigit = Number((contractClass.id.toBigInt() & U64_MASK) % 4n) + 1;
console.log(`Class digit: ${classDigit}`);

// 2. Mine a salt for the optimal target (~1000 attempts)
console.log("Mining solver salt...");
const {
  salt,
  address: solverAddress,
  xorTail,
} = await mineSolverSalt(ctx.deployer, classDigit, maxAttempts);
const target = deriveTarget(classDigit, xorTail);
console.log(`Solver address: ${solverAddress.toString()}`);
console.log(`Target: [${target.join(", ")}]`);

const discard = (values: Trio) =>
  challenge.methods.discard(ctx.deployer, values).send(sendOpts);
const draw = () => challenge.methods.draw(ctx.deployer).send(sendOpts);

function isNoOmenToDiscard(error: unknown): boolean {
  const msg = error instanceof Error ? error.message : String(error ?? "");
  return (
    msg.includes("Cannot return zero notes") ||
    msg.includes("no matching card found")
  );
}

// 3. Clear any leftover omen notes from previous attempts
console.log("Clearing leftover omens...");
for (const value of [1n, 2n, 3n, 4n, 5n]) {
  while (true) {
    try {
      await discard([value, 0n, 0n]);
    } catch (e: unknown) {
      if (isNoOmenToDiscard(e)) {
        break;
      }
      throw e;
    }
  }
}

// 4. Draw initial omen cards
console.log("Drawing initial omens...");
await draw();

// 5. Clear to [5]
console.log("Clearing to [5]...");
await discard([1n, 2n, 3n]);
await discard([4n, 0n, 0n]);

// 6. Build the target sequence based on class_digit
console.log(`Building target for class_digit=${classDigit}...`);
switch (classDigit) {
  case 1:
    await draw();
    await discard([5n, 0n, 0n]);
    break;
  case 2:
    await draw();
    await discard([1n, 3n, 5n]);
    await draw();
    await discard([2n, 4n, 5n]);
    break;
  case 3:
    await draw();
    await discard([1n, 2n, 5n]);
    await draw();
    await discard([3n, 4n, 5n]);
    break;
  case 4:
    await draw();
    await discard([1n, 2n, 3n]);
    await discard([5n, 0n, 0n]);
    await draw();
    await discard([4n, 5n, 0n]);
    break;
}

// 7. Register solver contract privately (no on-chain deploy needed)
console.log("Registering solver...");
const solverInstance = await getContractInstanceFromInstantiationParams(
  SummonersDeckSolverContractArtifact,
  { salt, deployer: ctx.deployer },
);
await registerContractAllowAlreadyRegistered(
  ctx.wallet,
  solverInstance,
  SummonersDeckSolverContractArtifact,
);
const solver = SummonersDeckSolverContract.at(
  solverInstance.address,
  ctx.wallet,
);

// 8. Create authwit: deployer authorizes the solver to call summon
const nonce = Fr.random();
const action = challenge.methods.summon(ctx.deployer, nonce);
const intent: CallIntent = {
  caller: solver.address,
  call: await action.getFunctionCall(),
};
const witness = await ctx.wallet.createAuthWit(ctx.deployer, intent);

// 9. Invoke through the solver
console.log("Invoking solver...");
const { receipt } = await solver.methods
  .invoke(challenge.address, ctx.deployer, nonce)
  .with({ authWitnesses: [witness] })
  .send(sendOpts);

console.log(`caller=${ctx.deployer.toString()}`);
console.log(`challenge=${addressValue}`);
console.log(`solver=${solver.address.toString()}`);
console.log(`txHash=${receipt.txHash.toString()}`);
