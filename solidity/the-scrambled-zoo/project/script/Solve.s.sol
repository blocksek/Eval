// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-ctf/CTFSolver.sol";

import "src/Challenge.sol";
import "src/TheScrambledZoo.sol";

contract Solve is CTFSolver {
    error FailedToSolve();

    function solve(address challengeAddress, address) internal override {
        Challenge challenge = Challenge(challengeAddress);
        TheScrambledZoo scrambledZoo = challenge.scrambledZoo();

        uint256 zkPk = vm.envUint("ZOOKEEPER_PK");
        address zk = vm.addr(zkPk);

        zk.call{value: 1 ether}('');
        
        vm.stopBroadcast();

        vm.startBroadcast(zkPk);
        scrambledZoo.solve();

        if (!scrambledZoo.isSolved()) revert FailedToSolve();
    }
}
