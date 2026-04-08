/*
 * Summoner's Deck Challenge
 * =========================
 *
 * Problem
 * -------
 * The SummonersDeck contract guards flag capture behind `summon()`, which
 * enforces three constraints on the caller (msg_sender):
 *
 *   1. The caller must NOT be the reader (the player's own address).
 *   2. The caller's bytecode must NOT have been published on-chain.
 *   3. The caller must NOT have been initialized on-chain.
 *
 * This means the caller must be a "phantom" contract -- one that exists
 * (has a deterministic address derived from class ID + salt + deployer)
 * but was never publicly deployed or initialized.
 *
 * Additionally, `summon()` reads the caller's contract instance and derives
 * a target note sequence from two sources:
 *
 *   - class_digit: `(contract_class_id as u64 % 4) + 1` -- a digit in {1,2,3,4}
 *     derived from the solver's contract class ID. This is fixed per compilation,
 *     so the player must compile a contract whose class ID yields the desired digit
 *     (or accept whichever digit they get, with a 25% chance for each).
 *
 *   - xor_tail: `((caller_address XOR salt) as u64) % 1000` -- a 3-digit value
 *     derived from the XOR of the solver's address and salt. Since the address
 *     depends on the salt, both change with every mining attempt.
 *
 * The last 3 decimal digits of xor_tail, combined with class_digit, must form
 * a permutation of {1, 2, 3, 4} (sum = 10, product = 24). These four digits
 * are arranged into a target sequence:
 *
 *   [5, class_digit, digit2, digit1, digit0, 0]
 *
 * The player's private note set must match this exact sequence.
 *
 * Concepts touched
 * ----------------
 * - Private deployment: registering a contract instance in the PXE without
 *   publishing bytecode or instance data on-chain.
 * - Contract instance model: understanding that an address is deterministically
 *   derived from (class_id, salt, deployer, init_hash, public_keys), so the
 *   address can be pre-computed and mined for specific properties.
 * - Class ID awareness: the class ID is determined at compile time, and its
 *   contribution to the target (class_digit) cannot be changed by salt mining.
 * - Salt mining: brute-forcing a salt such that `(address XOR salt) % 1000`
 *   yields 3 digits that, combined with class_digit, form {1,2,3,4}.
 * - AuthWit: the player authorizes the solver contract to call `summon()`
 *   on their behalf via an authentication witness.
 * - Private note manipulation: using `draw()` and `discard()` to build the
 *   exact note sequence the contract expects. Notes are returned by the PXE
 *   in historical (insertion) order -- understanding this is key to solving
 *   the rearrangement puzzle.
 *
 * Solution
 * --------
 * 1. Get class_digit: compute `(contract_class_id as u64 % 4) + 1` from the
 *    compiled artifact. This is fixed -- you cannot change it without recompiling.
 *
 * 2. Mine a salt for the optimal target. The optimal xor_tail depends on
 *    class_digit (see table below). ~1000 attempts per specific target.
 *
 * 3. Draw initial omen cards: call `draw(player)` to emit notes [1, 2, 3, 4, 5].
 *
 * 4. Rearrange notes to match the target using batch discard (up to 3 per tx).
 *    The strategy depends on class_digit:
 *
 *    class_digit=1 (6 txs): target [5,1,2,3,4,0]
 *      draw, discard [1,2,3], discard [4,0,0],       // clear to [5]
 *      draw, discard [5,0,0],                         // [5,1,2,3,4]
 *      summon
 *
 *    class_digit=2 (8 txs): target [5,2,4,1,3,0]
 *      draw, discard [1,2,3], discard [4,0,0],        // clear to [5]
 *      draw, discard [1,3,5],                          // [5,2,4]
 *      draw, discard [2,4,5],                          // [5,2,4,1,3]
 *      summon
 *
 *    class_digit=3 (8 txs): target [5,3,4,1,2,0]
 *      draw, discard [1,2,3], discard [4,0,0],        // clear to [5]
 *      draw, discard [1,2,5],                          // [5,3,4]
 *      draw, discard [3,4,5],                          // [5,3,4,1,2]
 *      summon
 *
 *    class_digit=4 (9 txs): target [5,4,1,2,3,0]
 *      draw, discard [1,2,3], discard [4,0,0],        // clear to [5]
 *      draw, discard [1,2,3], discard [5,0,0],         // [5,4]
 *      draw, discard [4,5,0],                          // [5,4,1,2,3]
 *      summon
 *
 * 5. Register the solver: use `wallet.registerContract()` to add the
 *    contract instance to the local PXE without any on-chain transaction.
 *
 * 6. Create an AuthWit: the player signs authorization for the solver contract
 *    to call `summon(player, nonce)` on the challenge.
 *
 * 7. Invoke through the solver: call `solver.invoke(challenge, player, nonce)`,
 *    which internally calls `SummonersDeck.summon()`. The solver passes all
 *    three deployment checks (not published, not initialized, not the reader).
 *
 * 8. The challenge verifies the note sequence matches the derived target,
 *    then enqueues `emit_flag()` on the FlagEmitter.
 */

import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { EmbeddedWallet } from "@aztec/wallets/embedded";
import { registerInitialLocalNetworkAccountsInWallet } from "@aztec/wallets/testing";
import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";
import { AztecAddress } from "@aztec/aztec.js/addresses";
import { Fr } from "@aztec/aztec.js/fields";
import { getContractClassFromArtifact } from "@aztec/stdlib/contract";
import { getContractInstanceFromInstantiationParams } from "@aztec/stdlib/contract";
import { type CallIntent } from "@aztec/aztec.js/authorization";
import { FlagEmitterContract } from "../../artifacts/FlagEmitter.ts";
import { SummonersDeckContract } from "../../artifacts/SummonersDeck.ts";
import {
  SummonersDeckSolverContract,
  SummonersDeckSolverContractArtifact,
} from "../../artifacts/SummonersDeckSolver.ts";
import { fieldCompressedString } from "../../../scripts/lib/shared.ts";

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

/**
 * Returns the optimal xor_tail for a given class_digit, minimizing
 * the number of draw/discard transactions needed to rearrange notes.
 */
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

/**
 * Mine a salt where xor_tail matches the optimal value for the given class_digit.
 * Expected ~1000 attempts.
 */
async function mineSolverSalt(
  deployer: AztecAddress,
  classDigit: number,
): Promise<{
  salt: Fr;
  address: AztecAddress;
  xorTail: bigint;
}> {
  const targetXorTail = getOptimalXorTail(classDigit);

  for (let i = 0; i < 100_000; i++) {
    const salt = Fr.random();
    const instance = await getContractInstanceFromInstantiationParams(
      SummonersDeckSolverContractArtifact,
      { salt, deployer },
    );
    const combined =
      (instance.address.toBigInt() & U64_MASK) ^ (salt.toBigInt() & U64_MASK);
    const xorTail = combined % 1000n;

    if (xorTail === targetXorTail) {
      return { salt, address: instance.address, xorTail };
    }
  }
  throw new Error("Could not mine a valid solver salt");
}

describe("SummonersDeck", () => {
  let wallet: EmbeddedWallet;
  let alice: AztecAddress;
  let emitter: FlagEmitterContract;
  let challenge: SummonersDeckContract;
  let classDigit: number;

  beforeAll(async () => {
    const aztecNode = createAztecNodeClient("http://localhost:8080", {});
    await waitForNode(aztecNode);
    wallet = await EmbeddedWallet.create(aztecNode, {
      pxeConfig: {
        dataDirectory: "pxe-ctf-summoners",
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

    ({ contract: challenge } = await SummonersDeckContract.deploy(
      wallet,
      emitter.address,
    ).send({ from: alice }));

    await emitter.methods
      .set_challenge(challenge.address, fieldCompressedString("summoners-deck"))
      .send({ from: alice });

    expect(
      (
        await emitter.methods
          .is_allowlisted(challenge.address)
          .simulate({ from: alice })
      ).result,
    ).toBe(true);

    const contractClass = await getContractClassFromArtifact(
      SummonersDeckSolverContractArtifact,
    );
    classDigit = Number((contractClass.id.toBigInt() & U64_MASK) % 4n) + 1;
  });

  afterAll(async () => {
    await wallet.stop();
  });

  it("should solve the summoner's deck", { timeout: 600_000 }, async () => {
    // 1. Mine a salt for the optimal target (~1000 attempts)
    console.log("Mining solver salt...");
    const {
      salt,
      address: solverAddress,
      xorTail,
    } = await mineSolverSalt(alice, classDigit);
    const target = deriveTarget(classDigit, xorTail);
    console.log(`Solver address: ${solverAddress.toString()}`);
    console.log(`Salt: ${salt.toString()}`);
    console.log(`Class digit: ${classDigit}`);
    console.log(`XOR tail: ${xorTail}`);
    console.log(`Target: [${target.join(", ")}]`);

    const send = { from: alice };
    const discard = (values: Trio) =>
      challenge.methods.discard(alice, values).send(send);
    const draw = () => challenge.methods.draw(alice).send(send);

    // 2. Draw initial omen cards (emission order: 1, 2, 3, 4, 5)
    await draw();

    // 3. Phase 1: Clear to [5] — discard [1,2,3] then [4]
    console.log("Phase 1: clearing to [5]...");
    await discard([1n, 2n, 3n]);
    await discard([4n, 0n, 0n]);

    // 4. Phase 2+3: Build the target sequence based on class_digit
    console.log(`Phase 2: building target for class_digit=${classDigit}...`);
    switch (classDigit) {
      case 1:
        // [5] → draw → [5,1,2,3,4,5] → discard [5] → [5,1,2,3,4]
        await draw();
        await discard([5n, 0n, 0n]);
        break;

      case 2:
        // [5] → draw → discard [1,3,5] → [5,2,4]
        //     → draw → discard [2,4,5] → [5,2,4,1,3]
        await draw();
        await discard([1n, 3n, 5n]);
        await draw();
        await discard([2n, 4n, 5n]);
        break;

      case 3:
        // [5] → draw → discard [1,2,5] → [5,3,4]
        //     → draw → discard [3,4,5] → [5,3,4,1,2]
        await draw();
        await discard([1n, 2n, 5n]);
        await draw();
        await discard([3n, 4n, 5n]);
        break;

      case 4:
        // [5] → draw → discard [1,2,3] → [5,4,5] → discard [5] → [5,4]
        //     → draw → discard [4,5] → [5,4,1,2,3]
        await draw();
        await discard([1n, 2n, 3n]);
        await discard([5n, 0n, 0n]);
        await draw();
        await discard([4n, 5n, 0n]);
        break;
    }

    // 5. Register solver contract privately (no deploy tx needed)
    const solverInstance = await getContractInstanceFromInstantiationParams(
      SummonersDeckSolverContractArtifact,
      { salt, deployer: alice },
    );
    expect(solverInstance.address.toString()).toBe(solverAddress.toString());
    await wallet.registerContract(
      solverInstance,
      SummonersDeckSolverContractArtifact,
    );
    const solver = SummonersDeckSolverContract.at(solverAddress, wallet);

    // 6. Create authwit: alice authorizes the solver to call summon
    const nonce = Fr.random();
    const action = challenge.methods.summon(alice, nonce);
    const intent: CallIntent = {
      caller: solver.address,
      call: await action.getFunctionCall(),
    };
    const witness = await wallet.createAuthWit(alice, intent);

    // 7. Invoke through the solver
    console.log("Invoking solver...");
    await solver.methods
      .invoke(challenge.address, alice, nonce)
      .with({ authWitnesses: [witness] })
      .send({ from: alice });

    // 8. Verify the flag was captured
    expect(
      (
        await emitter.methods
          .is_captured(challenge.address, alice)
          .simulate({ from: alice })
      ).result,
    ).toBe(true);
  });
});
