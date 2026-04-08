// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-ctf/CTFSolver.sol";

import "src/CheeseLending.sol";
import "script/exploit/Exploit.sol";

contract Solve is CTFSolver {
    function solve(address challengeAddress, address) internal override {
        CheeseLending challenge = CheeseLending(challengeAddress);
        Attacker attacker = new Attacker(challenge);
        attacker.run_exploit();
    }
}
