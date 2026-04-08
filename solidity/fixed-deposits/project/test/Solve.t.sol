// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import "src/Challenge.sol";
import "src/CtfDepositToken.sol";
import "src/DepositVault.sol";

contract SolveTest is Test {

    address private player = address(makeAddr("ALICE"));

    Challenge private challenge;

    function deploy() internal {
        CtfDepositToken token = new CtfDepositToken();
        DepositVault vault = new DepositVault(token);

        player = address(makeAddr("ALICE"));

        // Fund the vault with 500_000 tokens to pay interest
        token.transfer(address(vault), 500_000e18);
        // Give the player 20_000 tokens to work with
        token.transfer(player, 20_000e18);

        challenge = new Challenge(player, token, vault);

        // Transfer the vault manager role to the challenge contract
        vault.transferManager(address(challenge));
    }

    function testSolve() public {
        deploy();

        // Exploit code goes here

        // Check if the challenge is solved
        require(challenge.isSolved(), "Challenge not solved");
    }
}