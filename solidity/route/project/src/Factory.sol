// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {Deployer} from "src/Opcodes.sol";
import {UniswapV2Pair} from "src/pools/v2-core/UniswapV2Pair.sol";
import {WeightedPool} from "src/pools/weighted/WeightedPool.sol";
import {LBP} from "src/pools/LBP.sol";
import {ConstantSumPair} from "src/pools/ConstantSumPair.sol";

contract Factory {
    using SafeTransferLib for ERC20;

    // Pool implementations
    address internal uniswapV2Impl;
    address internal weightedPoolImpl;
    address internal constantSumPairImpl;
    address internal lbpImpl;

    // Registry
    address[] public pools;

    // For UniswapV2Pair
    address public feeTo;

    constructor() {
        uniswapV2Impl = address(new UniswapV2Pair());
        weightedPoolImpl = address(new WeightedPool());
        lbpImpl = address(new LBP());

        Deployer deployer = new Deployer();
        constantSumPairImpl = address(new ConstantSumPair(deployer.deployTables()));
    }

    // ========================================= MUTATIVE FUNCTIONS ========================================

    function setFeeTo(address _feeTo) external {
        require(feeTo == address(0));
        feeTo = _feeTo;
    }

    function deployUniswapV2Pair(address token0, address token1, uint256 token0Amount, uint256 token1Amount)
        external
        returns (address pair)
    {
        require(msg.sender == feeTo);

        pair = _clone(uniswapV2Impl);
        pools.push(pair);

        UniswapV2Pair(pair).initialize(token0, token1);

        ERC20(token0).safeTransferFrom(msg.sender, pair, token0Amount);
        ERC20(token1).safeTransferFrom(msg.sender, pair, token1Amount);
        UniswapV2Pair(pair).mint(msg.sender);
    }

    function deployWeightedPool(address[] memory tokens, uint256[] memory weights, uint256[] memory amounts)
        external
        returns (address pool)
    {
        require(msg.sender == feeTo);
        require(tokens.length == amounts.length, "Length mismatch");

        pool = _clone(weightedPoolImpl);
        pools.push(pool);

        WeightedPool(pool).initialize(tokens, weights);

        for (uint256 i = 0; i < tokens.length; i++) {
            ERC20(tokens[i]).safeTransferFrom(msg.sender, pool, amounts[i]);
        }
    }

    function deployLBP(
        uint256 tradingFee,
        address baseToken,
        address saleToken,
        uint256 virtualLiquidity,
        uint256 reserveSale
    ) external returns (address lbp) {
        require(msg.sender == feeTo);

        lbp = _clone(lbpImpl);
        pools.push(lbp);

        LBP(lbp).initialize(msg.sender, tradingFee, baseToken, saleToken, virtualLiquidity, reserveSale);

        ERC20(saleToken).safeTransferFrom(msg.sender, lbp, reserveSale);
    }

    function deployConstantSumPair(
        address tokenX,
        address tokenY,
        uint256 price,
        uint256 fee,
        uint256 amountXIn,
        uint256 amountYIn
    ) external returns (address pair) {
        require(msg.sender == feeTo);

        pair = _clone(constantSumPairImpl);
        pools.push(pair);

        ConstantSumPair(pair).initialize(tokenX, tokenY, price, fee, msg.sender);

        ERC20(tokenX).safeTransferFrom(msg.sender, address(this), amountXIn);
        ERC20(tokenY).safeTransferFrom(msg.sender, address(this), amountYIn);
        ERC20(tokenX).approve(pair, amountXIn);
        ERC20(tokenY).approve(pair, amountYIn);
        ConstantSumPair(pair).allocate(amountXIn, amountYIn);
    }

    // ========================================= HELPERS ========================================

    function poolsLength() external view returns (uint256) {
        return pools.length;
    }

    function _clone(address implementation) internal returns (address instance) {
        assembly ("memory-safe") {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(232, shl(96, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(120, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "Clone: create failed");
    }
}
