import {
  existsSync,
  readFileSync,
  realpathSync,
  rmSync,
  writeFileSync,
} from "node:fs";
import { isAbsolute, join, relative, resolve } from "node:path";
import { parseArgs } from "node:util";

import { loadContractArtifact } from "@aztec/aztec.js/abi";
import { AztecAddress } from "@aztec/aztec.js/addresses";
import {
  type InteractionWaitOptions,
  type SendReturn,
  type WaitOpts,
} from "@aztec/aztec.js/contracts";
import { Fr } from "@aztec/aztec.js/fields";
import { SponsoredFeePaymentMethod } from "@aztec/aztec.js/fee";
import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";
import type { SendOptions } from "@aztec/aztec.js/wallet";
import { SponsoredFPCContract } from "@aztec/noir-contracts.js/SponsoredFPC";
import { getContractInstanceFromInstantiationParams } from "@aztec/stdlib/contract";
import { GasFees, GasSettings } from "@aztec/stdlib/gas";
import type { ExecutionPayload } from "@aztec/stdlib/tx";
import { EmbeddedWallet } from "@aztec/wallets/embedded";

/**
 * `EmbeddedWallet` pre-simulates public execution before send. Some txs (e.g. poisoned-flag seed
 * with intentional public revert) must skip that; we delegate to `BaseWallet.sendTx` like
 * `BaseWallet.sendTx` on the same wallet instance.
 */
const baseWalletSendTx = Object.getPrototypeOf(
  Object.getPrototypeOf(EmbeddedWallet.prototype),
).sendTx as (
  this: EmbeddedWallet,
  payload: ExecutionPayload,
  opts: SendOptions<InteractionWaitOptions>,
) => Promise<SendReturn<InteractionWaitOptions>>;

export type SendTxWithOptionalSkipPresimOpts<
  W extends InteractionWaitOptions = undefined,
> = SendOptions<W> & { skipEmbeddedPresimulation?: boolean };

export async function sendTxWithOptionalSkipEmbeddedPresimulation<
  W extends InteractionWaitOptions = undefined,
>(
  wallet: EmbeddedWallet,
  executionPayload: ExecutionPayload,
  opts: SendTxWithOptionalSkipPresimOpts<W>,
): Promise<SendReturn<W>> {
  const { skipEmbeddedPresimulation, ...rest } = opts;
  if (skipEmbeddedPresimulation) {
    return baseWalletSendTx.call(wallet, executionPayload, rest) as Promise<
      SendReturn<W>
    >;
  }
  return wallet.sendTx(executionPayload, rest);
}

const CONFIG_PATH = join(process.cwd(), "testnet.json");

export const TESTNET_NODE_URL = "https://rpc.testnet.aztec-labs.com/";
export const TESTNET_PXE_DATA_DIRECTORY = "pxe-testnet";

const TESTNET_TX_WAIT_OPTIONS: WaitOpts = {
  timeout: 600,
  interval: 5,
};

export type TestnetConfig = {
  nodeUrl?: string;
  pxeDataDirectory?: string;
  fpcAddress?: string;
  fpcSalt?: string;
  fpcClaimSecret?: string;
  fpcClaimAmount?: string;
  fpcMessageHash?: string;
  fpcMessageLeafIndex?: string;
  deploymentSalt?: string;
  deployerSecretKey?: string;
  flagEmitter?: string;
  challenges?: Record<string, string>;
};

export type BaseOptions = {
  nodeUrl: string;
  pxeDataDirectory: string;
  deploymentSalt?: string;
  secretKey?: string;
  fpcAddress?: string;
  fpcSalt?: string;
  freshPxe?: boolean;
};

export type WalletContext = {
  wallet: EmbeddedWallet;
  deployer: AztecAddress;
};

export type FpcFeeOptions = {
  paymentMethod: SponsoredFeePaymentMethod;
  gasSettings: GasSettings;
};

export const BASE_PARSE_ARGS_OPTIONS = {
  "node-url": { type: "string" as const },
  "pxe-data-dir": { type: "string" as const },
  "deployment-salt": { type: "string" as const },
  "secret-key": { type: "string" as const },
  "fpc-address": { type: "string" as const },
  "fpc-salt": { type: "string" as const },
  "fresh-pxe": { type: "boolean" as const },
  help: { type: "boolean" as const, short: "h" as const },
};

export function loadTestnetConfig(): TestnetConfig {
  try {
    return JSON.parse(readFileSync(CONFIG_PATH, "utf8")) as TestnetConfig;
  } catch {
    return {};
  }
}

export function saveTestnetConfig(patch: Partial<TestnetConfig>): void {
  const existing = loadTestnetConfig();
  const merged: TestnetConfig = {
    ...existing,
    ...patch,
    challenges: { ...existing.challenges, ...patch.challenges },
  };
  writeFileSync(CONFIG_PATH, JSON.stringify(merged, null, 2) + "\n");
  console.log("Config saved to testnet.json");
}

export function fail(message: string): never {
  console.error(`\nError: ${message}\n`);
  process.exit(1);
}

/**
 * `registerContract` is idempotent when the contract is already registered; other
 * errors must propagate. Centralized so every script behaves the same (review feedback).
 */
export async function registerContractAllowAlreadyRegistered(
  wallet: EmbeddedWallet,
  ...args: Parameters<EmbeddedWallet["registerContract"]>
): Promise<void> {
  try {
    await wallet.registerContract(...args);
  } catch (e: unknown) {
    const msg = e instanceof Error ? e.message : String(e);
    if (!msg.toLowerCase().includes("already registered")) {
      throw e;
    }
  }
}

/**
 * Resolves the PXE data directory and ensures `--fresh-pxe` cannot delete outside
 * the project (including via `../` segments or symlinks).
 */
export function resolveSafePxeDataDirectoryForFreshDelete(
  userPath: string,
): string {
  const cwd = resolve(process.cwd());
  const resolved = resolve(cwd, userPath);
  const rel = relative(cwd, resolved);
  if (rel === "" || rel.startsWith("..") || isAbsolute(rel)) {
    fail(
      `Refusing --fresh-pxe: PXE data directory must lie inside the project directory.\n` +
        `  cwd: ${cwd}\n` +
        `  requested: ${userPath}\n` +
        `  resolved: ${resolved}`,
    );
  }
  if (existsSync(resolved)) {
    const realCwd = realpathSync(cwd);
    const realTarget = realpathSync(resolved);
    const relReal = relative(realCwd, realTarget);
    if (relReal === "" || relReal.startsWith("..") || isAbsolute(relReal)) {
      fail(
        `Refusing --fresh-pxe: path resolves outside the project via symlinks.\n` +
          `  cwd (real): ${realCwd}\n` +
          `  target (real): ${realTarget}`,
      );
    }
  }
  return resolved;
}

export function parseNonNegativeInteger(name: string, value: string): number {
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed < 0) {
    fail(`${name} must be a non-negative integer, received "${value}".`);
  }
  return parsed;
}

export function parseAddress(value: string): AztecAddress {
  try {
    return AztecAddress.fromString(value);
  } catch (error) {
    const reason = error instanceof Error ? error.message : String(error);
    fail(`Invalid address "${value}": ${reason}`);
  }
}

/** Encodes a <=31-char ASCII string into the FieldCompressedString shape. */
export function fieldCompressedString(s: string): { value: Fr } {
  if (s.length > 31) {
    throw new Error(`Challenge name too long (max 31 chars): "${s}"`);
  }
  const bytes = Buffer.alloc(32);
  Buffer.from(s, "ascii").copy(bytes, 1);
  return { value: Fr.fromBuffer(bytes) };
}

export function getTxWaitOptions(): WaitOpts {
  return TESTNET_TX_WAIT_OPTIONS;
}

export function resolveBaseOptions(
  args: ReturnType<typeof parseArgs>,
): BaseOptions {
  const cfg = loadTestnetConfig();

  const nodeUrl =
    (args.values["node-url"] as string | undefined) ??
    cfg.nodeUrl ??
    TESTNET_NODE_URL;

  const pxeDataDirectory =
    (args.values["pxe-data-dir"] as string | undefined) ??
    cfg.pxeDataDirectory ??
    TESTNET_PXE_DATA_DIRECTORY;

  const deploymentSalt =
    (args.values["deployment-salt"] as string | undefined) ??
    cfg.deploymentSalt;
  const secretKey =
    (args.values["secret-key"] as string | undefined) ?? cfg.deployerSecretKey;
  const fpcAddress =
    (args.values["fpc-address"] as string | undefined) ?? cfg.fpcAddress;
  const fpcSalt =
    (args.values["fpc-salt"] as string | undefined) ?? cfg.fpcSalt;
  const freshPxe = args.values["fresh-pxe"] as boolean | undefined;

  return {
    nodeUrl,
    pxeDataDirectory,
    deploymentSalt,
    secretKey,
    fpcAddress,
    fpcSalt,
    freshPxe,
  };
}

export async function createWalletContext(
  opts: BaseOptions,
): Promise<WalletContext> {
  if (!opts.secretKey) {
    fail(
      "A deployer secret key is required. Pass --secret-key or ensure testnet.json contains deployerSecretKey.",
    );
  }

  if (opts.freshPxe) {
    const resolved = resolveSafePxeDataDirectoryForFreshDelete(
      opts.pxeDataDirectory,
    );
    rmSync(resolved, { recursive: true, force: true });
    console.log(`Cleared PXE data directory: ${resolved}`);
  }

  const node = createAztecNodeClient(opts.nodeUrl, {});
  await waitForNode(node);

  const wallet = await EmbeddedWallet.create(node, {
    pxeConfig: {
      dataDirectory: opts.pxeDataDirectory,
      proverEnabled: true,
    },
  });

  const secret = Fr.fromHexString(opts.secretKey);
  const signingKeyNonce = opts.deploymentSalt
    ? Fr.fromHexString(opts.deploymentSalt)
    : Fr.ZERO;
  const accountManager = await wallet.createSchnorrAccount(
    secret,
    signingKeyNonce,
  );
  return { wallet, deployer: accountManager.address };
}

export async function setupFpcPayment(
  wallet: EmbeddedWallet,
  opts: Pick<BaseOptions, "fpcAddress" | "fpcSalt">,
): Promise<FpcFeeOptions> {
  if (!opts.fpcSalt) {
    fail("FPC salt not set. Run fund-fpc.ts first or pass --fpc-salt.");
  }

  const fpcSalt = Fr.fromHexString(opts.fpcSalt);
  const fpcArtifact = loadContractArtifact(
    SponsoredFPCContract.artifact as any,
  );
  const fpcInstance = await getContractInstanceFromInstantiationParams(
    fpcArtifact,
    {
      salt: fpcSalt,
      constructorArgs: [],
    },
  );

  if (
    opts.fpcAddress &&
    !fpcInstance.address.equals(AztecAddress.fromString(opts.fpcAddress))
  ) {
    fail(
      `Configured FPC address ${opts.fpcAddress} does not match salt ${opts.fpcSalt} ` +
        `(expected ${fpcInstance.address.toString()}).`,
    );
  }

  await registerContractAllowAlreadyRegistered(
    wallet,
    fpcInstance,
    fpcArtifact,
  );

  return {
    paymentMethod: new SponsoredFeePaymentMethod(fpcInstance.address),
    gasSettings: GasSettings.default({
      maxFeesPerGas: new GasFees(1_000_000n, 10_000_000_000_000n),
      maxPriorityFeesPerGas: new GasFees(1_000n, 100_000_000_000n),
    }),
  };
}
