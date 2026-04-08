// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-ctf/CTFSolver.sol";

import "script/exploit/Exploit.sol";

import { Remembrance } from "../src/test/RedMemoryTest.t.sol";
import { Challenge } from "src/Challenge.sol";

contract Solve is CTFSolver {
    function solve(address challengeAddress, address) internal override {
        Remembrance _remembrance = new Remembrance();
        Exploit exploit = new Exploit(Challenge(challengeAddress));
        exploit.exploit(address(_remembrance));
    }
}