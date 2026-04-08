// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";
import {Setup} from "src/Setup.sol";
import {UniswapV2Pair} from "src/pools/v2-core/UniswapV2Pair.sol";
import {WeightedPool} from "src/pools/weighted/WeightedPool.sol";
import {LBP} from "src/pools/LBP.sol";
import {ConstantSumPair} from "src/pools/ConstantSumPair.sol";
import {Factory} from "src/Factory.sol";

contract SolutionTest is Test {
    Setup internal setup;

    function setUp() public {
        Factory factory = new Factory();
        setup = new Setup(factory, address(this));
    }

    function test_outputEdges() public view {
        for (uint256 i; i < 120; i++) {
            string memory s;
            uint256 logicalIndex = _logicalPoolIndex(i);

            address pool = setup.pools(i);
            if (logicalIndex < 30) {
                s = string.concat(s, ERC20(UniswapV2Pair(pool).token0()).name(), " ");
                s = string.concat(s, ERC20(UniswapV2Pair(pool).token1()).name());
            } else if (logicalIndex < 60) {
                s = string.concat(s, ConstantSumPair(pool).tokenX().name(), " ");
                s = string.concat(s, ConstantSumPair(pool).tokenY().name());
            } else if (logicalIndex < 90) {
                for (uint256 j; j < WeightedPool(pool).tokensLength(); j++) {
                    s = string.concat(s, WeightedPool(pool).tokens(j).name(), " ");
                }
            } else {
                s = string.concat(s, LBP(pool).baseToken().name(), " ");
                s = string.concat(s, LBP(pool).saleToken().name());
            }

            console.log(s);
        }
    }

    function test_outputPools() public view {
        for (uint256 i; i < 120; i++) {
            uint256 logicalIndex = _logicalPoolIndex(i);

            address pool = setup.pools(i);
            if (logicalIndex < 30) {
                UniswapV2Pair pair = UniswapV2Pair(pool);
                (uint112 reserve0, uint112 reserve1,) = pair.getReserves();

                console.log("UNISWAP pool", i);
                console.log("token0", ERC20(pair.token0()).name());
                console.log("token1", ERC20(pair.token1()).name());
                console.log("reserve0", uint256(reserve0));
                console.log("reserve1", uint256(reserve1));
            } else if (logicalIndex < 60) {
                ConstantSumPair pair = ConstantSumPair(pool);

                console.log("CONSTANT_SUM pool", i);
                console.log("tokenX", pair.tokenX().name());
                console.log("tokenY", pair.tokenY().name());
                console.log("price", pair.price());
                console.log("fee", pair.fee());
                console.log("reserveX", pair.reserveX());
                console.log("reserveY", pair.reserveY());
            } else if (logicalIndex < 90) {
                WeightedPool weightedPool = WeightedPool(pool);
                uint256 tokenCount = weightedPool.tokensLength();

                console.log("WEIGHTED pool", i);
                for (uint256 j; j < tokenCount; j++) {
                    ERC20 token = weightedPool.tokens(j);
                    console.log("token", token.name());
                    console.log("weight", weightedPool.weights(j));
                    console.log("balance", token.balanceOf(pool));
                }
            } else {
                LBP lbp = LBP(pool);

                console.log("LBP pool", i);
                console.log("baseToken", lbp.baseToken().name());
                console.log("saleToken", lbp.saleToken().name());
                console.log("tradingFee", lbp.tradingFee());
                console.log("virtualLiquidity", lbp.virtualLiquidity());
                console.log("reserveBase", lbp.reserveBase());
                console.log("reserveSale", lbp.reserveSale());
            }
            console.log("");
        }
    }

    function _logicalPoolIndex(uint256 poolIndex) internal pure returns (uint256) {
        return (37 * poolIndex + 17) % 120;
    }
}
