import {
  MediumFlagCaptureContract,
  MediumFlagCaptureContractArtifact,
} from "../../artifacts/MediumFlagCapture.ts";
import { FlagEmitterContract } from "../../artifacts/FlagEmitter.ts";
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { EmbeddedWallet } from "@aztec/wallets/embedded";
import { registerInitialLocalNetworkAccountsInWallet } from "@aztec/wallets/testing";
import {
  createAztecNodeClient,
  waitForNode,
  type AztecNode,
} from "@aztec/aztec.js/node";
import { AztecAddress } from "@aztec/aztec.js/addresses";
import { Fr } from "@aztec/aztec.js/fields";
import { getContractInstanceFromInstantiationParams } from "@aztec/stdlib/contract";
import { fieldCompressedString } from "../../../scripts/lib/shared.ts";

describe("MediumFlagCapture", () => {
  let wallet: EmbeddedWallet;
  let alice: AztecAddress;
  let contract: MediumFlagCaptureContract;
  let emitter: FlagEmitterContract;
  let aztecNode: AztecNode;
  let derivedContract: MediumFlagCaptureContract;

  beforeAll(async () => {
    aztecNode = createAztecNodeClient("http://localhost:8080", {});
    await waitForNode(aztecNode);
    wallet = await EmbeddedWallet.create(aztecNode, {
      pxeConfig: {
        dataDirectory: "pxe-ctf-medium",
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

    ({ contract } = await MediumFlagCaptureContract.deploy(
      wallet,
      emitter.address,
    ).send({
      from: alice,
      universalDeploy: false,
      contractAddressSalt: Fr.ZERO,
    } as any));

    await emitter.methods
      .set_challenge(
        contract.address,
        fieldCompressedString("medium-flag-capture"),
      )
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

  it("should capture the flag", async () => {
    expect(
      (
        await emitter.methods
          .is_captured(contract.address, alice)
          .simulate({ from: alice })
      ).result,
    ).toBe(false);

    // Read the `owner` from the flag-emitter's immutable storage (slot 1)
    // and use it as the deployer to derive the medium flag contract address.
    const ownerField = await aztecNode.getPublicStorageAt(
      "latest",
      emitter.address,
      new Fr(1n),
    );
    const deployer = AztecAddress.fromField(ownerField);

    const derivedInstance = await getContractInstanceFromInstantiationParams(
      MediumFlagCaptureContractArtifact,
      {
        constructorArgs: [emitter.address],
        salt: Fr.ZERO,
        deployer,
      },
    );
    derivedContract = MediumFlagCaptureContract.at(
      derivedInstance.address,
      wallet,
    );

    await derivedContract.methods.capture_flag().send({ from: alice });

    expect(
      (
        await emitter.methods
          .is_captured(derivedInstance.address, alice)
          .simulate({ from: alice })
      ).result,
    ).toBe(true);
  });

  it("should revert on double capture", async () => {
    await expect(
      derivedContract.methods.capture_flag().send({ from: alice }),
    ).rejects.toMatchObject({
      message: expect.stringContaining("already captured"),
    });
  });
});
