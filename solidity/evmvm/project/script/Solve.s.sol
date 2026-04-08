// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.33;

import "forge-ctf/CTFSolver.sol";

import "src/Challenge.sol";

contract Solve is CTFSolver {
    function solve(address challengeAddress, address) internal override {
        Challenge challenge = Challenge(challengeAddress);
        require(challenge.isSolved(), "Solver not implemented for evmvm yet");
    }
}
