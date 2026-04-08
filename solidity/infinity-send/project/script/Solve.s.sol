// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {CTFSolver} from "forge-ctf/CTFSolver.sol";
import {Exploit} from "script/exploit/Exploit.sol";
import {Challenge} from "src/Challenge.sol";

contract Solve is CTFSolver {
    function solve(address challengeAddress, address) internal override {
        Challenge challenge = Challenge(challengeAddress);
        Exploit exploit = new Exploit(challenge);
        exploit.exploit();
        require(challenge.isSolved(), "Not solved");
    }
}
