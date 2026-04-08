// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {FixedPoint} from "./FixedPoint.sol";

contract WeightedPool {
    using FixedPoint for uint256;

    uint256 public constant MIN_WEIGHT = 1e16; // 1%
    uint256 public constant MAX_IN_RATIO = 30e16; // 30%

    address public immutable factory;

    ERC20[] public tokens;
    uint256[] public weights;

    constructor() {
        factory = msg.sender;
    }

    function initialize(address[] memory _tokens, uint256[] memory _weights) external {
        require(msg.sender == factory, "Not factory");
        require(tokens.length == 0, "Already initialized");

        require(_tokens.length <= 3, "Too many tokens");
        require(_tokens.length == _weights.length, "Length mismatch");

        uint256 weightsSum = 0;
        for (uint256 i = 0; i < _tokens.length; i++) {
            require(_weights[i] >= MIN_WEIGHT, "Weight too small");

            tokens.push(ERC20(_tokens[i]));
            weights.push(_weights[i]);

            weightsSum += _weights[i];
        }
        require(weightsSum == FixedPoint.ONE, "Weights must sum to 1");
    }

    // ========================================= MUTATIVE FUNCTIONS ========================================

    function swapExactIn(uint256 tokenInIndex, uint256 tokenOutIndex, uint256 amountIn, uint256 minAmountOut)
        external
        returns (uint256 amountOut)
    {
        require(tokenInIndex < tokens.length, "Invalid tokenInIndex");
        require(tokenOutIndex < tokens.length, "Invalid tokenOutIndex");

        ERC20 tokenIn = tokens[tokenInIndex];
        ERC20 tokenOut = tokens[tokenOutIndex];

        uint256 balanceIn = tokenIn.balanceOf(address(this));
        uint256 balanceOut = tokenOut.balanceOf(address(this));

        amountOut = _getAmountOut(balanceIn, weights[tokenInIndex], balanceOut, weights[tokenOutIndex], amountIn);
        require(amountOut >= minAmountOut, "Slippage");

        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenOut.transfer(msg.sender, amountOut);
    }

    // ========================================= HELPERS ========================================

    function tokensLength() external view returns (uint256) {
        return tokens.length;
    }

    function computeK(uint256[] memory normalizedWeights, uint256[] memory balances) public pure returns (uint256 k) {
        k = FixedPoint.ONE;
        for (uint256 i = 0; i < normalizedWeights.length; ++i) {
            k = k.mulUp(balances[i].powUp(normalizedWeights[i]));
        }

        require(k != 0, "Zero K");
    }

    function _getAmountOut(uint256 balanceIn, uint256 weightIn, uint256 balanceOut, uint256 weightOut, uint256 amountIn)
        internal
        pure
        returns (uint256 amountOut)
    {
        require(amountIn <= balanceIn.mulDown(MAX_IN_RATIO), "amountIn too large");

        uint256 denominator = balanceIn + amountIn;
        uint256 base = balanceIn.divUp(denominator);

        uint256 exponent = weightIn.divDown(weightOut);
        uint256 power = base.powUp(exponent);

        amountOut = balanceOut.mulDown(power.complement());
    }
}
