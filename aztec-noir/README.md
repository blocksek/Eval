# Wonderland CTF 2026 — Aztec Noir Challenges

These are the Aztec Noir challenges from [Wonderland CTF 2026](https://ctf.wonderland.xyz). They are written in [Noir](https://noir-lang.org/), the smart contract language for the [Aztec](https://aztec.network/) network.

## Challenges

| Challenge | Description |
|-----------|-------------|
| [Lucky Guess](src/nr/challenges/lucky_guess/) | Beat the Cheshire Cat at five rounds of rock-paper-scissors |
| [Medium Flag Capture](src/nr/challenges/medium_flag_capture/) | Can you guess the salt? |
| [Poisoned Flag](src/nr/challenges/poisoned_flag/) | Break the curse before the poison sets in |
| [Summoner's Deck](src/nr/challenges/summoners_deck/) | Arrange the omen cards and summon the phantom |
| [The Observatory](src/nr/challenges/the_observatory/) | Prove the singularity before the signal fades |

## Running locally

### Prerequisites

- [Node.js](https://nodejs.org/) >= 22
- [Yarn](https://yarnpkg.com/) >= 1.22
- Aztec toolset (version `4.2.0-aztecnr-rc.2`)

### 1. Install the Aztec toolset

```bash
VERSION=4.2.0-aztecnr-rc.2 bash -i <(curl -sL https://install.aztec.network/4.2.0-aztecnr-rc.2)
aztec-up 4.2.0-aztecnr-rc.2
```

### 2. Install dependencies and build

```bash
yarn
yarn ccc
```

### 3. Start a local Aztec network

```bash
aztec start --local-network
```

### 4. Solve a challenge

The challenge contracts live in `src/nr/challenges/`. Read the contract code, understand the vulnerability, and write your own solution.

To write your solution, create a new test file (e.g. `src/ts/my_solution.test.ts`). Each test needs to:

1. Connect to the local Aztec node
2. Deploy the `FlagEmitter` and the challenge contract
3. Allowlist the challenge in the emitter
4. **Execute your exploit**
5. Verify the flag was captured

Here's the minimal template:

```typescript
import { FlagEmitterContract } from "../artifacts/FlagEmitter.ts";
import { LuckyGuessContract } from "../artifacts/LuckyGuess.ts"; // swap for your challenge
import { describe, it, expect, beforeAll, afterAll } from "vitest";
import { EmbeddedWallet } from "@aztec/wallets/embedded";
import { registerInitialLocalNetworkAccountsInWallet } from "@aztec/wallets/testing";
import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";
import { AztecAddress } from "@aztec/aztec.js/addresses";
import { fieldCompressedString } from "../../scripts/lib/shared.ts";

describe("MySolution", () => {
  let wallet: EmbeddedWallet;
  let alice: AztecAddress;
  let contract: LuckyGuessContract;
  let emitter: FlagEmitterContract;

  beforeAll(async () => {
    const aztecNode = createAztecNodeClient("http://localhost:8080", {});
    await waitForNode(aztecNode);
    wallet = await EmbeddedWallet.create(aztecNode, {
      pxeConfig: {
        dataDirectory: "pxe-ctf-my-solution",
        proverEnabled: false,
      },
    });

    [alice] = await registerInitialLocalNetworkAccountsInWallet(wallet);

    // Deploy FlagEmitter
    ({ contract: emitter } = await FlagEmitterContract.deploy(wallet, alice)
      .send({ from: alice }));

    // Deploy the challenge
    ({ contract } = await LuckyGuessContract.deploy(wallet, emitter.address)
      .send({ from: alice }));

    // Allowlist the challenge
    await emitter.methods
      .set_challenge(contract.address, fieldCompressedString("lucky-guess"))
      .send({ from: alice });
  });

  afterAll(async () => {
    await wallet.stop();
  });

  it("should capture the flag", async () => {
    // -----------------------------------------------
    // YOUR EXPLOIT HERE
    // -----------------------------------------------

    // Verify it worked
    expect(
      (await emitter.methods.is_captured(contract.address, alice)
        .simulate({ from: alice })).result,
    ).toBe(true);
  });
});
```

Run your solution:

```bash
yarn test:js src/ts/my_solution.test.ts
```

### 5. Reference solutions

The `src/ts/` directory and `scripts/challenges/` contain **reference solutions** that show how each challenge was solved during the competition. If you want to solve the challenges yourself first, avoid reading these files.

To run all reference solutions:

```bash
yarn test:js
```

To run a single one:

```bash
yarn test:js src/ts/lucky_guess/lucky_guess.test.ts
```

## Project structure

```
src/
  nr/
    challenges/       # The 5 challenge contracts (Noir)
    flag_emitter/     # Shared flag registry contract
    test/             # Auxiliary contracts used by tests
  ts/                 # Reference solutions (vitest) — CONTAINS SPOILERS
scripts/
  challenges/         # Solve scripts per challenge — CONTAINS SPOILERS
  lib/                # Shared utilities
```
