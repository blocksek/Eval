// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {Factory} from "./Factory.sol";
import {NoRevertOnFailureToken, RegularToken} from "./Tokens.sol";

contract Setup {
    address public immutable PLAYER;

    uint256 internal constant TOKEN_COUNT = 50;
    uint256 internal constant POOL_COUNT = 120;
    uint256 internal constant POOL_ORDER_STEP = 37;
    uint256 internal constant POOL_ORDER_OFFSET = 17;
    uint256 internal constant VALUE_SCALE = 1e18;
    uint256 internal constant NO_REVERT_TOKEN_ID = 23;

    uint256 public constant CLAIM_AMOUNT = 100_000e6;
    uint256 public constant TARGET_AMOUNT = 280_000e6;

    // Registry of all tokens and pools
    address[] public tokens;
    address[] public pools;

    constructor(Factory factory, address player) {
        // Set feeTo in Factory
        factory.setFeeTo(address(this));

        // Deploy all token contracts
        for (uint256 i; i < TOKEN_COUNT; i++) {
            string memory symbol = string.concat("USD-", toString(i));
            RegularToken token = i == NO_REVERT_TOKEN_ID
                ? new NoRevertOnFailureToken(symbol, symbol, 6)
                : new RegularToken(symbol, symbol, 6);

            token.mint(address(this), 1_000_000_000e6);
            token.approve(address(factory), type(uint256).max);

            tokens.push(address(token));
        }

        // Deploy all pools in a deterministic shuffled order so the registry is mixed.
        for (uint256 i; i < POOL_COUNT; i++) {
            _deployShuffledPool(factory, _logicalPoolIndex(i));
        }

        // Transfer USD-0 to the player for the challenge
        PLAYER = player;
        ERC20(tokens[0]).transfer(PLAYER, CLAIM_AMOUNT);
    }

    // Note: Challenge is solved when you have sufficient USD-49
    function isSolved() external view returns (bool) {
        return ERC20(tokens[49]).balanceOf(PLAYER) >= TARGET_AMOUNT;
    }

    // Helper function to get the number of tokens and pools
    function noOfTokensAndPools() external view returns (uint256, uint256) {
        return (tokens.length, pools.length);
    }

    // ======================================== HELPER FUNCTIONS ========================================

    function _deployUniswapPools(Factory factory) internal {
        // 30 Uniswap V2 pools: 20 backbone edges + 10 long-range shortcuts.
        for (uint256 i; i < 20; i++) {
            _deployUniswap(factory, _perm(i), _perm(i + 1), (2_500_000 + (i % 5) * 450_000) * 1e6);
        }
        for (uint256 i; i < 10; i++) {
            (uint256 tokenAId, uint256 tokenBId) = _extraUniswapPair(i);
            _deployUniswap(factory, tokenAId, tokenBId, (8_000_000 + (i % 5) * 1_200_000) * 1e6);
        }
    }

    function _deployConstantSumPools(Factory factory) internal {
        // 30 ConstantSum pools: 20 expensive backbone edges + 10 cheap express lanes.
        for (uint256 i; i < 20; i++) {
            _deployConstantSum(
                factory, _perm(20 + i), _perm(21 + i), (8 + (i % 5) * 4) * 1e15, (1_800_000 + (i % 4) * 350_000) * 1e6
            );
        }
        for (uint256 i; i < 10; i++) {
            (uint256 tokenAId, uint256 tokenBId) = _extraConstantSumPair(i);
            _deployConstantSum(factory, tokenAId, tokenBId, (5 + (i % 5)) * 1e14, (8_500_000 + (i % 5) * 950_000) * 1e6);
        }
    }

    function _deployWeightedPools(Factory factory) internal {
        // 30 Weighted pools: 10 weighted backbone pairs, 5 heavier shortcut pairs, 15 tri-token hubs.
        _deployWeightedBackbone(factory);
        _deployWeightedShortcuts(factory);
        _deployWeightedTriads(factory);
    }

    function _deployWeightedBackbone(Factory factory) internal {
        for (uint256 i; i < 10; i++) {
            (uint256 weightA, uint256 weightB) = _ringPairWeights(i);
            _deployWeightedPair(
                factory, _perm(40 + i), _perm(41 + i), weightA, weightB, (7_500_000 + (i % 5) * 900_000) * 1e6
            );
        }
    }

    function _deployWeightedShortcuts(Factory factory) internal {
        for (uint256 i; i < 5; i++) {
            (uint256 tokenAId, uint256 tokenBId) = _extraWeightedPair(i);
            (uint256 weightA, uint256 weightB) = _extraPairWeights(i);
            _deployWeightedPair(factory, tokenAId, tokenBId, weightA, weightB, (14_000_000 + i * 1_000_000) * 1e6);
        }
    }

    function _deployWeightedTriads(Factory factory) internal {
        for (uint256 i; i < 15; i++) {
            _deployWeightedTriadPool(factory, i);
        }
    }

    function _deployWeightedTriadPool(Factory factory, uint256 index) internal {
        (uint256 tokenAId, uint256 tokenBId, uint256 tokenCId) = _weightedTriad(index);
        uint256 scale = (10_500_000 + (index % 5) * 1_100_000) * 1e6;

        address[] memory poolTokens = new address[](3);
        poolTokens[0] = tokens[tokenAId];
        poolTokens[1] = tokens[tokenBId];
        poolTokens[2] = tokens[tokenCId];

        uint256[] memory weights = new uint256[](3);
        (weights[0], weights[1], weights[2]) = _triadWeights(index);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = _weightedAmount(tokenAId, weights[0], scale);
        amounts[1] = _weightedAmount(tokenBId, weights[1], scale);
        amounts[2] = _weightedAmount(tokenCId, weights[2], scale);

        pools.push(factory.deployWeightedPool(poolTokens, weights, amounts));
    }

    function _deployLBPPools(Factory factory) internal {
        // 30 directed LBPs. These add one-way shortcuts without being required for connectivity.
        for (uint256 i; i < 30; i++) {
            (uint256 baseTokenId, uint256 saleTokenId) = _lbpPair(i);
            _deployLBP(
                factory, baseTokenId, saleTokenId, (15 + (i % 7) * 5) * 1e14, (11_000_000 + (i % 5) * 1_250_000) * 1e6
            );
        }
    }

    function _deployShuffledPool(Factory factory, uint256 logicalIndex) internal {
        if (logicalIndex < 30) {
            _deployUniswapPool(factory, logicalIndex);
            return;
        }

        if (logicalIndex < 60) {
            _deployConstantSumPool(factory, logicalIndex - 30);
            return;
        }

        if (logicalIndex < 90) {
            _deployWeightedPool(factory, logicalIndex - 60);
            return;
        }

        _deployLBPPool(factory, logicalIndex - 90);
    }

    function _logicalPoolIndex(uint256 poolIndex) internal pure returns (uint256) {
        return (POOL_ORDER_STEP * poolIndex + POOL_ORDER_OFFSET) % POOL_COUNT;
    }

    function _deployUniswapPool(Factory factory, uint256 index) internal {
        if (index < 20) {
            _deployUniswap(factory, _perm(index), _perm(index + 1), (2_500_000 + (index % 5) * 450_000) * 1e6);
            return;
        }

        (uint256 tokenAId, uint256 tokenBId) = _extraUniswapPair(index - 20);

        uint256 scale = index == 24 ? 200_000_000e6 : (8_000_000 + (index % 5) * 1_200_000) * 1e6;
        _deployUniswap(factory, tokenAId, tokenBId, scale);
    }

    function _deployConstantSumPool(Factory factory, uint256 index) internal {
        if (index < 20) {
            _deployConstantSum(
                factory,
                _perm(20 + index),
                _perm(21 + index),
                (8 + (index % 5) * 4) * 1e15,
                (1_800_000 + (index % 4) * 350_000) * 1e6
            );
            return;
        }

        (uint256 tokenAId, uint256 tokenBId) = _extraConstantSumPair(index - 20);
        uint256 fee = index == 24 ? 1e14 : (5 + (index % 5)) * 1e14;
        uint256 scale = index == 24 ? 20_000_000e6 : 100_000e6;
        _deployConstantSum(factory, tokenAId, tokenBId, fee, scale);
    }

    function _deployWeightedPool(Factory factory, uint256 index) internal {
        if (index < 10) {
            (uint256 weightA, uint256 weightB) = _ringPairWeights(index);
            _deployWeightedPair(
                factory,
                _perm(40 + index),
                _perm(41 + index),
                weightA,
                weightB,
                (7_500_000 + (index % 5) * 900_000) * 1e6
            );
            return;
        }

        if (index < 15) {
            (uint256 tokenAId, uint256 tokenBId) = _extraWeightedPair(index - 10);
            (uint256 weightA, uint256 weightB) = _extraPairWeights(index - 10);

            uint256 scale =
                index == 11 ? 171_667e6 : index == 13 ? 200_000_000e6 : (14_000_000 + (index - 10) * 1_000_000) * 1e6;
            _deployWeightedPair(factory, tokenAId, tokenBId, weightA, weightB, scale);
            return;
        }

        _deployWeightedTriadPool(factory, index - 15);
    }

    function _deployLBPPool(Factory factory, uint256 index) internal {
        (uint256 baseTokenId, uint256 saleTokenId) = _lbpPair(index);
        uint256 tradingFee = index == 15 ? 0 : (15 + (index % 7) * 5) * 1e14;
        uint256 scale = index == 15 ? 200_000_000e6 : (11_000_000 + (index % 5) * 1_250_000) * 1e6;
        _deployLBP(factory, baseTokenId, saleTokenId, tradingFee, scale);
    }

    function _deployUniswap(Factory factory, uint256 tokenAId, uint256 tokenBId, uint256 scale) internal {
        pools.push(
            factory.deployUniswapV2Pair(
                tokens[tokenAId], tokens[tokenBId], _reserveAmount(tokenAId, scale), _reserveAmount(tokenBId, scale)
            )
        );
    }

    function _deployConstantSum(Factory factory, uint256 tokenXId, uint256 tokenYId, uint256 fee, uint256 scale)
        internal
    {
        pools.push(
            factory.deployConstantSumPair(
                tokens[tokenXId],
                tokens[tokenYId],
                _value(tokenXId) * VALUE_SCALE / _value(tokenYId),
                fee,
                _reserveAmount(tokenXId, scale),
                _reserveAmount(tokenYId, scale)
            )
        );
    }

    function _deployWeightedPair(
        Factory factory,
        uint256 tokenAId,
        uint256 tokenBId,
        uint256 weightA,
        uint256 weightB,
        uint256 scale
    ) internal {
        address[] memory poolTokens = new address[](2);
        poolTokens[0] = tokens[tokenAId];
        poolTokens[1] = tokens[tokenBId];

        uint256[] memory weights = new uint256[](2);
        weights[0] = weightA;
        weights[1] = weightB;

        uint256[] memory amounts = new uint256[](2);
        amounts[0] = _weightedAmount(tokenAId, weightA, scale);
        amounts[1] = _weightedAmount(tokenBId, weightB, scale);

        pools.push(factory.deployWeightedPool(poolTokens, weights, amounts));
    }

    function _deployLBP(Factory factory, uint256 baseTokenId, uint256 saleTokenId, uint256 tradingFee, uint256 scale)
        internal
    {
        pools.push(
            factory.deployLBP(
                tradingFee,
                tokens[baseTokenId],
                tokens[saleTokenId],
                _reserveAmount(baseTokenId, scale),
                _reserveAmount(saleTokenId, scale)
            )
        );
    }

    function _perm(uint256 index) internal pure returns (uint256) {
        return (17 * index + 3) % TOKEN_COUNT;
    }

    function _value(uint256 tokenId) internal pure returns (uint256) {
        return (90 + ((13 * (49 - tokenId) + 7) % 21)) * 1e16;
    }

    function _reserveAmount(uint256 tokenId, uint256 scale) internal pure returns (uint256) {
        return scale * VALUE_SCALE / _value(tokenId);
    }

    function _weightedAmount(uint256 tokenId, uint256 weight, uint256 scale) internal pure returns (uint256) {
        return scale * weight / _value(tokenId);
    }

    function _extraUniswapPair(uint256 index) internal pure returns (uint256 tokenAId, uint256 tokenBId) {
        uint8[10] memory tokenA = [uint8(2), 3, 4, 9, 11, 15, 17, 23, 24, 38];
        uint8[10] memory tokenB = [uint8(13), 25, 40, 12, 37, 47, 24, 47, 49, 46];
        return (tokenA[index], tokenB[index]);
    }

    function _extraConstantSumPair(uint256 index) internal pure returns (uint256 tokenAId, uint256 tokenBId) {
        uint8[10] memory tokenA = [uint8(0), 4, 4, 10, 37, 12, 16, 20, 21, 27];
        uint8[10] memory tokenB = [uint8(10), 15, 47, 40, 31, 41, 36, 36, 36, 42];
        return (tokenA[index], tokenB[index]);
    }

    function _extraWeightedPair(uint256 index) internal pure returns (uint256 tokenAId, uint256 tokenBId) {
        uint8[5] memory tokenA = [uint8(12), 13, 17, 31, 36];
        uint8[5] memory tokenB = [uint8(13), 23, 40, 49, 47];
        return (tokenA[index], tokenB[index]);
    }

    function _weightedTriad(uint256 index)
        internal
        pure
        returns (uint256 tokenAId, uint256 tokenBId, uint256 tokenCId)
    {
        uint8[15] memory tokenA = [uint8(33), 26, 26, 49, 7, 21, 0, 1, 20, 27, 21, 19, 15, 12, 12];
        uint8[15] memory tokenB = [uint8(35), 46, 11, 17, 42, 6, 19, 36, 40, 46, 40, 4, 1, 14, 47];
        uint8[15] memory tokenC = [uint8(3), 14, 13, 20, 28, 25, 38, 39, 8, 48, 41, 39, 3, 48, 16];
        return (tokenA[index], tokenB[index], tokenC[index]);
    }

    function _lbpPair(uint256 index) internal pure returns (uint256 baseTokenId, uint256 saleTokenId) {
        uint8[30] memory baseToken = [
            uint8(27),
            5,
            15,
            14,
            47,
            42,
            30,
            29,
            6,
            12,
            24,
            38,
            47,
            36,
            3,
            0,
            11,
            19,
            49,
            46,
            33,
            13,
            28,
            15,
            3,
            44,
            12,
            18,
            7,
            27
        ];
        uint8[30] memory saleToken = [
            uint8(41),
            2,
            39,
            18,
            10,
            44,
            4,
            25,
            8,
            26,
            27,
            34,
            9,
            24,
            8,
            11,
            7,
            23,
            23,
            49,
            42,
            6,
            21,
            29,
            40,
            48,
            27,
            42,
            13,
            21
        ];
        return (baseToken[index], saleToken[index]);
    }

    function _ringPairWeights(uint256 index) internal pure returns (uint256 weightA, uint256 weightB) {
        uint256 slot = index % 5;

        if (slot == 0) return (50e16, 50e16);
        if (slot == 1) return (65e16, 35e16);
        if (slot == 2) return (35e16, 65e16);
        if (slot == 3) return (70e16, 30e16);
        return (45e16, 55e16);
    }

    function _extraPairWeights(uint256 index) internal pure returns (uint256 weightA, uint256 weightB) {
        if (index == 0) return (55e16, 45e16);
        if (index == 1) return (60e16, 40e16);
        if (index == 2) return (50e16, 50e16);
        if (index == 3) return (30e16, 70e16);
        return (45e16, 55e16);
    }

    function _triadWeights(uint256 index) internal pure returns (uint256 weightA, uint256 weightB, uint256 weightC) {
        uint256 slot = index % 5;

        if (slot == 0) return (50e16, 30e16, 20e16);
        if (slot == 1) return (45e16, 35e16, 20e16);
        if (slot == 2) return (55e16, 25e16, 20e16);
        if (slot == 3) return (60e16, 25e16, 15e16);
        return (40e16, 35e16, 25e16);
    }

    /// @dev Returns the base 10 decimal representation of `value`.
    function toString(uint256 value) internal pure returns (string memory result) {
        /// @solidity memory-safe-assembly
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit), but
            // we allocate 0xa0 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 word for the trailing zeros padding, 1 word for the length,
            // and 3 words for a maximum of 78 digits.
            result := add(mload(0x40), 0x80)
            mstore(0x40, add(result, 0x20)) // Allocate memory.
            mstore(result, 0) // Zeroize the slot after the string.

            let end := result // Cache the end of the memory to calculate the length later.
            let w := not(0) // Tsk.
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            for { let temp := value } 1 {} {
                result := add(result, w) // `sub(result, 1)`.
                // Store the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(result, add(48, mod(temp, 10)))
                temp := div(temp, 10) // Keep dividing `temp` until zero.
                if iszero(temp) { break }
            }
            let n := sub(end, result)
            result := sub(result, 0x20) // Move the pointer 32 bytes back to make room for the length.
            mstore(result, n) // Store the length.
        }
    }
}
