// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-ctf/CTFSolver.sol";
import "forge-std/Vm.sol";
import "forge-std/Test.sol";
import {ERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

import "script/exploit/Exploit.sol";

contract Solve is CTFSolver {
    function solve(address challengeAddress, address player) internal override {
        Challenge challenge = Challenge(challengeAddress);

        Exploit exploit = new Exploit(challenge);
        ERC20(address(challenge.token())).transfer(address(exploit), ERC20(address(challenge.token())).balanceOf(player));
        exploit.exploit();
        require(challenge.isSolved(), "Challenge not solved");
    }
}
