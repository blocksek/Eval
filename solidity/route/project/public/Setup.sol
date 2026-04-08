// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ERC20} from "@solmate/tokens/ERC20.sol";

contract Setup {
    // The player address
    address public immutable PLAYER;

    // The number of tokens and pools
    uint256 public constant TOKEN_COUNT = 50;
    uint256 public constant POOL_COUNT = 120;

    // Claim and target amounts
    uint256 public constant CLAIM_AMOUNT = 100_000e6;
    uint256 public constant TARGET_AMOUNT = 280_000e6;

    // Registry of all tokens and pools
    address[] public tokens;
    address[] public pools;

    constructor(address player) {
        /*
        Hmm, I seem to have lost this part of the code. Guess we'll have to look at the bytecode...

        I vaguely recall that there were four types of pools.
        Some of the pools might have had interesting bugs that we could exploit.
        I think one of the tokens was a "no-revert-on-failure" token.

        Also, I found graph.png lying around in my recycle bin. Maybe it will be useful.
        */

        // Transfer USD-0 to the player for the challenge
        PLAYER = player;
        ERC20(tokens[0]).transfer(PLAYER, CLAIM_AMOUNT);
    }

    // Note: Challenge is solved when you have sufficient USD-49
    function isSolved() external view returns (bool) {
        return ERC20(tokens[49]).balanceOf(PLAYER) >= TARGET_AMOUNT;
    }
}
