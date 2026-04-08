import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";
import type { FeePaymentMethod } from "@aztec/aztec.js/fee";
import { SPONSORED_FPC_SALT } from "@aztec/constants";
import { PublicKeys } from "@aztec/aztec.js/keys";
import { Fr } from "@aztec/aztec.js/fields";
import { SponsoredFPCContractArtifact } from "@aztec/noir-contracts.js/SponsoredFPC";
import {
  FunctionCall,
  FunctionSelector,
  FunctionType,
} from "@aztec/stdlib/abi";
import { AztecAddress } from "@aztec/aztec.js/addresses";
import {
  computeContractAddressFromInstance,
  getContractClassFromArtifact,
} from "@aztec/stdlib/contract";
import type { GasSettings } from "@aztec/stdlib/gas";
import { ExecutionPayload, mergeExecutionPayloads } from "@aztec/stdlib/tx";
import { EmbeddedWallet } from "@aztec/wallets/embedded";
import { registerInitialLocalNetworkAccountsInWallet } from "@aztec/wallets/testing";
import { afterAll, beforeAll, describe, expect, it } from "vitest";

import { ExternalRevertHelperContract } from "../../artifacts/ExternalRevertHelper.ts";
import { FlagEmitterContract } from "../../artifacts/FlagEmitter.ts";
import { PoisonedFlagContract } from "../../artifacts/PoisonedFlag.ts";
import {
  fieldCompressedString,
  sendTxWithOptionalSkipEmbeddedPresimulation,
} from "../../../scripts/lib/shared.ts";

class LocalSponsoredPaymentMethod implements FeePaymentMethod {
  constructor(private paymentContract: AztecAddress) {}

  async getExecutionPayload(): Promise<ExecutionPayload> {
    return new ExecutionPayload(
      [
        FunctionCall.from({
          name: "sponsor_unconditionally",
          to: this.paymentContract,
          selector: await FunctionSelector.fromSignature(
            "sponsor_unconditionally()",
          ),
          type: FunctionType.PRIVATE,
          hideMsgSender: false,
          isStatic: false,
          args: [],
          returnTypes: [],
        }),
      ],
      [],
      [],
      [],
      this.paymentContract,
    );
  }

  getAsset(): Promise<AztecAddress> {
    return Promise.resolve(this.paymentContract);
  }

  getFeePayer(): Promise<AztecAddress> {
    return Promise.resolve(this.paymentContract);
  }

  getGasSettings(): GasSettings | undefined {
    return;
  }
}

describe("PoisonedFlag", () => {
  let wallet: EmbeddedWallet;
  let alice: AztecAddress;
  let bob: AztecAddress;
  let charlie: AztecAddress;
  /** Canonical Sponsored FPC on the sandbox, derived from `@aztec/constants` salt + artifact class id. */
  let canonicalSponsoredFpc: AztecAddress;
  let emitter: FlagEmitterContract;
  let reverter: ExternalRevertHelperContract;
  let contract: PoisonedFlagContract;

  beforeAll(async () => {
    const aztecNode = createAztecNodeClient("http://localhost:8080", {});
    await waitForNode(aztecNode);
    wallet = await EmbeddedWallet.create(aztecNode, {
      pxeConfig: {
        dataDirectory: "pxe-ctf-poisoned-flag",
        proverEnabled: false,
      },
    });

    [alice, bob, charlie] =
      await registerInitialLocalNetworkAccountsInWallet(wallet);

    // Register the canonical SponsoredFPC with the local PXE (pre-deployed by the sandbox).
    const sponsoredFpcClassId = (
      await getContractClassFromArtifact(SponsoredFPCContractArtifact)
    ).id;
    const sponsoredFpcSalt = new Fr(SPONSORED_FPC_SALT);
    const sponsoredFpcInstance = {
      version: 1 as const,
      salt: sponsoredFpcSalt,
      deployer: AztecAddress.ZERO,
      currentContractClassId: sponsoredFpcClassId,
      originalContractClassId: sponsoredFpcClassId,
      initializationHash: Fr.ZERO,
      publicKeys: PublicKeys.default(),
    };
    canonicalSponsoredFpc =
      await computeContractAddressFromInstance(sponsoredFpcInstance);
    await wallet.registerContract(
      { ...sponsoredFpcInstance, address: canonicalSponsoredFpc },
      SponsoredFPCContractArtifact,
    );

    ({ contract: emitter } = await FlagEmitterContract.deploy(
      wallet,
      alice,
    ).send({
      from: alice,
    }));

    ({ contract: reverter } = await ExternalRevertHelperContract.deploy(
      wallet,
    ).send({
      from: alice,
    }));

    ({ contract } = await PoisonedFlagContract.deploy(
      wallet,
      emitter.address,
    ).send({
      from: alice,
    }));

    await emitter.methods
      .set_challenge(contract.address, fieldCompressedString("poisoned-flag"))
      .send({
        from: alice,
      });
  });

  afterAll(async () => {
    await wallet.stop();
  });

  it("rejects the ordering trick drink,FPC,take_antidote,capture,get_poisoned", async () => {
    const sponsored = new LocalSponsoredPaymentMethod(canonicalSponsoredFpc);
    const sponsoredPayload = await sponsored.getExecutionPayload();

    const merged = mergeExecutionPayloads([
      await contract.methods.drink_poison().request(),
      sponsoredPayload,
      await contract.methods.take_antidote().request(),
      await contract.methods.capture_flag().request(),
      await contract.methods.get_poisoned().request(),
    ]);

    await expect(wallet.sendTx(merged, { from: alice })).rejects.toThrow(
      "antidote already pending",
    );
  });

  it("requires drink,FPC,get_poisoned,revert then FPC,take_antidote,capture", async () => {
    const sponsored = new LocalSponsoredPaymentMethod(canonicalSponsoredFpc);
    const sponsoredPayload = await sponsored.getExecutionPayload();
    const drinkPayload = await contract.methods.drink_poison().request();
    const getPoisonedPayload = await contract.methods.get_poisoned().request();
    const revertPayload = await reverter.methods.arm_revert().request();

    const seedMerged = mergeExecutionPayloads([
      drinkPayload,
      sponsoredPayload,
      getPoisonedPayload,
      revertPayload,
    ]);

    await sendTxWithOptionalSkipEmbeddedPresimulation(wallet, seedMerged, {
      from: alice,
      wait: { dontThrowOnRevert: true },
      skipEmbeddedPresimulation: true,
    });

    expect(
      (await contract.methods.is_seeded(alice).simulate({ from: alice }))
        .result,
    ).toBe(true);
    expect(
      (await contract.methods.is_poisoned(alice).simulate({ from: alice }))
        .result,
    ).toBe(false);
    expect(
      (
        await emitter.methods
          .is_captured(contract.address, alice)
          .simulate({ from: alice })
      ).result,
    ).toBe(false);

    const solvePayload = mergeExecutionPayloads([
      sponsoredPayload,
      await contract.methods.take_antidote().request(),
      await contract.methods.capture_flag().request(),
    ]);

    await wallet.sendTx(solvePayload, { from: alice });

    expect(
      (
        await emitter.methods
          .is_captured(contract.address, alice)
          .simulate({ from: alice })
      ).result,
    ).toBe(true);
  });

  it("rejects naive FPC,drink,take_antidote,capture one-shot solve", async () => {
    const sponsored = new LocalSponsoredPaymentMethod(canonicalSponsoredFpc);
    const merged = mergeExecutionPayloads([
      await sponsored.getExecutionPayload(),
      await contract.methods.drink_poison().request(),
      await contract.methods.take_antidote().request(),
      await contract.methods.capture_flag().request(),
    ]);

    await expect(wallet.sendTx(merged, { from: bob })).rejects.toThrow();
  });

  it("rejects naive drink,FPC,get_poisoned then FPC,take_antidote,capture because poison persists", async () => {
    const sponsored = new LocalSponsoredPaymentMethod(canonicalSponsoredFpc);
    const seedMerged = mergeExecutionPayloads([
      await contract.methods.drink_poison().request(),
      await sponsored.getExecutionPayload(),
      await contract.methods.get_poisoned().request(),
    ]);

    await wallet.sendTx(seedMerged, {
      from: bob,
      wait: { dontThrowOnRevert: true },
    });

    expect(
      (await contract.methods.is_seeded(bob).simulate({ from: bob })).result,
    ).toBe(true);
    expect(
      (await contract.methods.is_poisoned(bob).simulate({ from: bob })).result,
    ).toBe(true);

    const solveMerged = mergeExecutionPayloads([
      await sponsored.getExecutionPayload(),
      await contract.methods.take_antidote().request(),
      await contract.methods.capture_flag().request(),
    ]);

    await expect(wallet.sendTx(solveMerged, { from: bob })).rejects.toThrow();
  });

  it("rejects naive drink,get_poisoned,revert without explicit FPC (poison not committed in setup)", async () => {
    // Without an explicit FPC the wallet inserts end_setup() at the account-contract
    // level, before all user calls.  drink_poison() therefore runs in the revertible app phase:
    // its drink nullifier is rolled back on revert and is absent from the global tree.
    // commit_poison (teardown) asserts nullifier_exists_unsafe(drink) → fails.
    // Note: charlie's drink/seed nullifiers are distinct from the cure
    // nullifier used in the "fresh users" test below, so there is no state conflict.
    const seedMerged = mergeExecutionPayloads([
      await contract.methods.drink_poison().request(),
      await contract.methods.get_poisoned().request(),
      await reverter.methods.arm_revert().request(),
    ]);

    await sendTxWithOptionalSkipEmbeddedPresimulation(wallet, seedMerged, {
      from: charlie,
      wait: { dontThrowOnRevert: true },
      skipEmbeddedPresimulation: true,
    });

    expect(
      (await contract.methods.is_seeded(charlie).simulate({ from: charlie }))
        .result,
    ).toBe(false);
  });

  it("fresh users cannot solve with only FPC,take_antidote,capture", async () => {
    const sponsored = new LocalSponsoredPaymentMethod(canonicalSponsoredFpc);
    const solveMerged = mergeExecutionPayloads([
      await sponsored.getExecutionPayload(),
      await contract.methods.take_antidote().request(),
      await contract.methods.capture_flag().request(),
    ]);

    await expect(
      wallet.sendTx(solveMerged, { from: charlie }),
    ).rejects.toThrow();
  });
});
