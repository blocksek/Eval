import { parseArgs } from "node:util";

import { MediumFlagCaptureContract } from "../../../src/artifacts/MediumFlagCapture.ts";
import {
  BASE_PARSE_ARGS_OPTIONS,
  createWalletContext,
  fail,
  getTxWaitOptions,
  loadTestnetConfig,
  parseAddress,
  resolveBaseOptions,
  setupFpcPayment,
} from "../../lib/shared.ts";

function printHelp() {
  console.log(`Usage: yarn capture:medium [options]

Options:
  --address <aztec-address>  MediumFlagCapture address (defaults to testnet.json)
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
  },
});

if (args.values.help) {
  printHelp();
  process.exit(0);
}

const opts = resolveBaseOptions(args);
const cfg = loadTestnetConfig();
const addressValue =
  (args.values.address as string | undefined) ??
  cfg.challenges?.MediumFlagCapture;
if (!addressValue) {
  fail("Missing --address.");
}

const ctx = await createWalletContext(opts);
const wait = getTxWaitOptions();
const fee = await setupFpcPayment(ctx.wallet, opts);

const contract = MediumFlagCaptureContract.at(
  parseAddress(addressValue),
  ctx.wallet,
);
const interaction = contract.methods.capture_flag();
const { receipt } = await interaction.send({
  from: ctx.deployer,
  fee,
  wait,
} as any);

console.log(`caller=${ctx.deployer.toString()}`);
console.log(`challenge=${addressValue}`);
console.log(`txHash=${receipt.txHash.toString()}`);
