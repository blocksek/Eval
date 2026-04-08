import { LuckyGuessContract } from "../../artifacts/LuckyGuess.ts";
import { FlagEmitterContract } from "../../artifacts/FlagEmitter.ts";
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { EmbeddedWallet } from "@aztec/wallets/embedded";
import { registerInitialLocalNetworkAccountsInWallet } from "@aztec/wallets/testing";
import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";
import { AztecAddress } from "@aztec/aztec.js/addresses";
import { randomBytes } from "@aztec/foundation/crypto/random";
import { fieldCompressedString } from "../../../scripts/lib/shared.ts";

const FR_MODULUS =
  0x30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001n;

const RPS_ERROR = "Cheshire Cat";
const MAX_OFFSET = 20;

function replicateFrRandom(counter: number): bigint {
  const buf = Buffer.alloc(64);
  for (let i = 0; i < 64; i++) {
    buf[i] = (counter >> (i * 8)) & 0xff;
  }
  return BigInt("0x" + buf.toString("hex")) % FR_MODULUS;
}

function predictCatMove(counter: number): number {
  const field = replicateFrRandom(counter);
  return Number(field & 0xffn) % 3;
}

function computeWinningMoves(
  baseCounter: number,
): [number, number, number, number, number] {
  return Array.from({ length: 5 }, (_, i) => {
    const catMove = predictCatMove(baseCounter + i);
    return (catMove + 1) % 3;
  }) as [number, number, number, number, number];
}

/**
 * Exploits the SEED-based deterministic PRNG to predict the cat's moves.
 * Probes the current counter via randomBytes(4), then scans offsets to
 * account for framework-internal randomBytes() calls between the probe
 * and the oracle invocations inside capture_flag.
 */
async function sendWithPredictedMoves(
  contract: LuckyGuessContract,
  sender: AztecAddress,
): Promise<void> {
  for (let offset = 0; offset <= MAX_OFFSET; offset++) {
    const probe = randomBytes(4);
    const counter = probe.readUInt32LE(0) + 1 + offset;
    const moves = computeWinningMoves(counter);
    try {
      await contract.methods.capture_flag(moves).send({ from: sender });
      return;
    } catch (e: any) {
      const msg = String(e?.message ?? e);
      if (msg.includes(RPS_ERROR)) {
        continue;
      }
      throw e;
    }
  }
  throw new Error(
    `Failed to capture — counter offset out of inclusive range 0..${MAX_OFFSET}`,
  );
}

// SEED must be set before EmbeddedWallet.create() triggers the first
// randomBytes() call, which lazily creates the RandomnessSingleton.
// A unique seed per run avoids "Existing nullifier" collisions on a
// persistent sandbox. The prediction algorithm is seed-agnostic.
process.env.SEED = String(Math.floor(Math.random() * 2 ** 32));

describe("LuckyGuess", () => {
  let wallet: EmbeddedWallet;
  let alice: AztecAddress;
  let contract: LuckyGuessContract;
  let emitter: FlagEmitterContract;

  beforeAll(async () => {
    const aztecNode = createAztecNodeClient("http://localhost:8080", {});
    await waitForNode(aztecNode);
    wallet = await EmbeddedWallet.create(aztecNode, {
      pxeConfig: {
        dataDirectory: "pxe-ctf-lucky",
        proverEnabled: false,
      },
    });

    [alice] = await registerInitialLocalNetworkAccountsInWallet(wallet);

    ({ contract: emitter } = await FlagEmitterContract.deploy(
      wallet,
      alice,
    ).send({
      from: alice,
    }));

    ({ contract } = await LuckyGuessContract.deploy(
      wallet,
      emitter.address,
    ).send({
      from: alice,
    }));

    await emitter.methods
      .set_challenge(contract.address, fieldCompressedString("lucky-guess"))
      .send({
        from: alice,
      });

    expect(
      (
        await emitter.methods
          .is_allowlisted(contract.address)
          .simulate({ from: alice })
      ).result,
    ).toBe(true);
  });

  afterAll(async () => {
    await wallet.stop();
  });

  it("should capture the flag via SEED prediction", async () => {
    expect(
      (
        await emitter.methods
          .is_captured(contract.address, alice)
          .simulate({ from: alice })
      ).result,
    ).toBe(false);

    await sendWithPredictedMoves(contract, alice);

    expect(
      (
        await emitter.methods
          .is_captured(contract.address, alice)
          .simulate({ from: alice })
      ).result,
    ).toBe(true);
  });

  it("should revert on double capture", async () => {
    for (let offset = 0; offset <= MAX_OFFSET; offset++) {
      const probe = randomBytes(4);
      const counter = probe.readUInt32LE(0) + 1 + offset;
      const moves = computeWinningMoves(counter);
      try {
        await contract.methods.capture_flag(moves).send({ from: alice });
        throw new Error("Expected capture to be rejected");
      } catch (e: any) {
        const msg = String(e?.message ?? e);
        if (msg.includes(RPS_ERROR)) {
          continue;
        }
        expect(msg).toContain("already captured");
        break;
      }
    }

    expect(
      (
        await emitter.methods
          .is_captured(contract.address, alice)
          .simulate({ from: alice })
      ).result,
    ).toBe(true);
  });
});
