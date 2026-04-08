// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-ctf/CTFSolver.sol";

import {Setup} from "src/Setup.sol";
import {Exploit} from "./exploit/Exploit.sol";

contract Solve is CTFSolver {
    function solve(address challengeAddress, address) internal override {
        Setup challenge = Setup(challengeAddress);

        // Route does not expose a single `solve()` entrypoint, so the exploit contract
        // is the place to encode the actual sequence when this scaffold is filled in.
        Exploit exploit = new Exploit(challenge);
        exploit.exploit();
    }
}
