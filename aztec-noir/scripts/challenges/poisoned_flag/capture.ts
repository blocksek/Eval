import { parseArgs } from "node:util";

import { NO_FROM } from "@aztec/aztec.js/account";
import { AztecAddress } from "@aztec/aztec.js/addresses";
import { Fr } from "@aztec/aztec.js/fields";
import { getContractInstanceFromInstantiationParams } from "@aztec/stdlib/contract";
import { mergeExecutionPayloads } from "@aztec/stdlib/tx";

import { ExternalRevertHelperContract } from "../../../src/artifacts/ExternalRevertHelper.ts";
import {
  PoisonedFlagContract,
  PoisonedFlagContractArtifact,
} from "../../../src/artifacts/PoisonedFlag.ts";
import {
  BASE_PARSE_ARGS_OPTIONS,
  createWalletContext,
  fail,
  getTxWaitOptions,
  loadTestnetConfig,
  parseAddress,
  registerContractAllowAlreadyRegistered,
  resolveBaseOptions,
  sendTxWithOptionalSkipEmbeddedPresimulation,
  setupFpcPayment,
} from "../../lib/shared.ts";

function printHelp() {
  console.log(`Usage: yarn capture:poisoned [options]

Options:
  --address <aztec-address>   PoisonedFlag address (defaults to testnet.json)
  --node-url <url>            Override the Aztec node URL
  --pxe-data-dir <path>       Override the PXE data directory
  --secret-key <hex>          Deployer secret key
  --fpc-address <addr>        SponsoredFPC address
  --fpc-salt <hex>            SponsoredFPC salt
  --deployment-salt <hex>     Salt for account derivation
  --fresh-pxe                 Clear PXE data directory before starting
  --help                      Show this message`);
}

const args = parseArgs({
  options: {
    ...BASE_PARSE_ARGS_OPTIONS,
    address: { type: "string" },
  },
});

if (args.values.help) {
  printHelp();
  process.exit(0);
}

const opts = resolveBaseOptions(args);
const cfg = loadTestnetConfig();
const addressValue =
  (args.values.address as string | undefined) ?? cfg.challenges?.PoisonedFlag;
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

const challengeInstance = await getContractInstanceFromInstantiationParams(
  PoisonedFlagContractArtifact,
  {
    salt: Fr.ZERO,
    constructorArgs: [emitterAddress],
    deployer: AztecAddress.ZERO,
  },
);
await registerContractAllowAlreadyRegistered(
  ctx.wallet,
  challengeInstance,
  PoisonedFlagContractArtifact,
);

const challenge = PoisonedFlagContract.at(challengeAddress, ctx.wallet);

// `from: deployer` makes the wallet build a real account tx for every `.simulate()` (very slow on testnet).
// Public views only need chain state; `NO_FROM` → DefaultEntrypoint / node-fast path — seconds instead of hanging.
console.log("Querying is_seeded / is_poisoned…");
const viewSimOpts = {
  from: NO_FROM,
  skipFeeEnforcement: true,
} as const;
const { result: seededRead } = await challenge.methods
  .is_seeded(ctx.deployer)
  .simulate(viewSimOpts);
const { result: poisonedRead } = await challenge.methods
  .is_poisoned(ctx.deployer)
  .simulate(viewSimOpts);
// `.simulate()` returns `{ result, ... }`, not a bare boolean — do not use `if (simulate(...))`.
const seeded = seededRead === true;
const poisoned = poisonedRead === true;

let seedReceipt;
let reverterAddress;

if (seeded && poisoned) {
  fail(
    "This deployer already ran a setup that committed seed but not the reverting path (poisoned is still true). " +
      "capture_flag requires poisoned=false. Use a different --secret-key or redeploy PoisonedFlag, then run the full seed (drink → FPC → get_poisoned → revert).",
  );
}

if (seeded && !poisoned) {
  console.log(
    "Reverting seed already on-chain (seeded=true, poisoned=false) — skipping seed tx and reverter deploy.",
  );
} else {
  const { contract: reverter } = await ExternalRevertHelperContract.deploy(
    ctx.wallet,
  ).send(sendOpts);
  reverterAddress = reverter.address;

  const fpcPayload = await fee.paymentMethod.getExecutionPayload();
  const seedPayload = mergeExecutionPayloads([
    await challenge.methods.drink_poison().request(),
    fpcPayload,
    await challenge.methods.get_poisoned().request(),
    await reverter.methods.arm_revert().request(),
  ]);

  const seedSendResult = await sendTxWithOptionalSkipEmbeddedPresimulation(
    ctx.wallet,
    seedPayload,
    {
      from: ctx.deployer,
      fee: { gasSettings: fee.gasSettings },
      wait: { ...wait, dontThrowOnRevert: true },
      skipEmbeddedPresimulation: true,
    },
  );
  if (!("receipt" in seedSendResult)) {
    fail("Expected mined seed transaction receipt.");
  }
  seedReceipt = seedSendResult.receipt;
  console.log(
    `Seed tx mined: ${seedReceipt.txHash.toString()} status=${seedReceipt.status} ` +
      `(app revert is expected; wait uses dontThrowOnRevert — script continues).`,
  );
}

const solveFpcPayload = await fee.paymentMethod.getExecutionPayload();
const solvePayload = mergeExecutionPayloads([
  solveFpcPayload,
  await challenge.methods.take_antidote().request(),
  await challenge.methods.capture_flag().request(),
]);

const { receipt: solveReceipt } =
  await sendTxWithOptionalSkipEmbeddedPresimulation(ctx.wallet, solvePayload, {
    from: ctx.deployer,
    fee: { gasSettings: fee.gasSettings },
    wait,
    // Same class of issue as the seed tx: embedded presimulation runs public execution
    // (verify_and_emit → seeded read) in a context that can disagree with standalone
    // `is_seeded` / actual inclusion. Skip presim so we send the same payload the node proves.
    skipEmbeddedPresimulation: true,
  });

console.log(`caller=${ctx.deployer.toString()}`);
console.log(`challenge=${challenge.address.toString()}`);
if (reverterAddress) {
  console.log(`reverter=${reverterAddress.toString()}`);
}
if (seedReceipt) {
  console.log(`seedTxHash=${seedReceipt.txHash.toString()}`);
  console.log(`seedStatus=${seedReceipt.status}`);
}
console.log(`solveTxHash=${solveReceipt.txHash.toString()}`);
console.log(`solveStatus=${solveReceipt.status}`);
