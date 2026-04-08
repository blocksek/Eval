// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";

contract LBP {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;

    error NotFactory();
    error AlreadyInitialized();
    error FeeTooLarge();
    error VirtualLiquidityTooSmall();
    error SaleNotStarted();
    error InsufficientAmountOut();
    error InsufficientLiquidity();
    error InsufficientAmountIn();

    uint256 public constant MAX_TRADING_FEE = 0.1e18; // 10%

    uint256 public constant PROTECTION_DURATION = 86400;

    address public immutable factory;

    // AMM tokens
    ERC20 public baseToken;
    ERC20 public saleToken;

    // Protocol treasury address
    address public treasury;

    // Fee (%) for buying and selling tokens
    uint256 public tradingFee;

    // Sale parameters
    uint256 public virtualLiquidity;
    uint256 public reserveBase;
    uint256 public reserveSale;
    uint256 public startTime;
    uint256 public initialReserveSale;

    // ======================================== CONSTRUCTOR ========================================

    constructor() {
        factory = msg.sender;
    }

    function initialize(
        address _treasury,
        uint256 _tradingFee,
        address _baseToken,
        address _saleToken,
        uint256 _virtualLiquidity,
        uint256 _reserveSale
    ) external {
        if (msg.sender != factory) revert NotFactory();
        if (reserveBase != 0) revert AlreadyInitialized();

        if (_virtualLiquidity == 0) revert VirtualLiquidityTooSmall();
        if (_tradingFee > MAX_TRADING_FEE) revert FeeTooLarge();

        baseToken = ERC20(_baseToken);
        saleToken = ERC20(_saleToken);
        treasury = _treasury;
        tradingFee = _tradingFee;

        virtualLiquidity = _virtualLiquidity;
        reserveBase = _virtualLiquidity;
        reserveSale = _reserveSale;

        startTime = block.timestamp;
        initialReserveSale = _reserveSale;
    }

    // ======================================== USER FUNCTIONS ========================================

    function buyTokens(uint256 amountIn, uint256 minAmountOut) external returns (uint256 amountOut) {
        if (reserveBase == 0) revert SaleNotStarted();

        (uint256 feeAmount, uint256 amountInAfterFees) = _subtractFee(amountIn);
        amountOut = _getAmountOut(amountInAfterFees, reserveBase, reserveSale);
        amountOut = _adjustSaleAmountOut(amountOut);

        if (amountOut < minAmountOut) revert InsufficientAmountOut();

        reserveBase += amountInAfterFees;
        reserveSale -= amountOut;

        baseToken.safeTransferFrom(msg.sender, address(this), amountIn);
        baseToken.safeTransfer(treasury, feeAmount);
        saleToken.safeTransfer(msg.sender, amountOut);
    }

    function sellTokens(uint256 amountIn, uint256 minAmountOut) external returns (uint256 amountOut) {
        if (reserveBase == 0) revert SaleNotStarted();

        amountOut = _getAmountOut(amountIn, reserveSale, reserveBase);

        // In theory, this check should never fail
        uint256 actualLiquidity = reserveBase - virtualLiquidity;
        if (amountOut > actualLiquidity) revert InsufficientLiquidity();

        reserveSale += amountIn;
        reserveBase -= amountOut;

        uint256 feeAmount;
        (feeAmount, amountOut) = _subtractFee(amountOut);

        if (amountOut < minAmountOut) revert InsufficientAmountOut();

        saleToken.safeTransferFrom(msg.sender, address(this), amountIn);
        baseToken.safeTransfer(treasury, feeAmount);
        baseToken.safeTransfer(msg.sender, amountOut);
    }

    function swapTokens(uint256 baseAmountOut, uint256 saleAmountOut) external {
        if (reserveBase == 0) revert SaleNotStarted();

        saleAmountOut = _adjustSaleAmountOut(saleAmountOut);

        uint256 actualLiquidity = reserveBase - virtualLiquidity;
        if (baseAmountOut > actualLiquidity) revert InsufficientLiquidity();

        baseToken.safeTransfer(msg.sender, baseAmountOut);
        saleToken.safeTransfer(msg.sender, saleAmountOut);

        uint256 reserveBaseAfter = baseToken.balanceOf(address(this)) + virtualLiquidity;
        uint256 reserveSaleAfter = saleToken.balanceOf(address(this));

        uint256 baseAmountIn = reserveBaseAfter > reserveBase ? reserveBaseAfter - reserveBase : 0;
        uint256 saleAmountIn = reserveSaleAfter > reserveSale ? reserveSaleAfter - reserveSale : 0;

        (uint256 feeAmountBase,) = _subtractFee(baseAmountIn);
        (uint256 feeAmountSale,) = _subtractFee(saleAmountIn);
        baseToken.safeTransfer(treasury, feeAmountBase);
        saleToken.safeTransfer(treasury, feeAmountSale);

        reserveBaseAfter -= feeAmountBase;
        reserveSaleAfter -= feeAmountSale;
        if (reserveBaseAfter * reserveSaleAfter < reserveBase * reserveSale) revert InsufficientLiquidity();

        reserveBase = reserveBaseAfter;
        reserveSale = reserveSaleAfter;
    }

    // ======================================== VIEW FUNCTIONS ========================================

    function previewBuyTokens(uint256 amountIn) external view returns (uint256 amountOut) {
        amountIn -= amountIn.mulWadDown(tradingFee);
        amountOut = _getAmountOut(amountIn, reserveBase, reserveSale);
        amountOut = _adjustSaleAmountOut(amountOut);
    }

    function previewSellTokens(uint256 amountIn) external view returns (uint256 amountOut) {
        amountOut = _getAmountOut(amountIn, reserveSale, reserveBase);

        uint256 actualLiquidity = reserveBase - virtualLiquidity;
        if (amountOut > actualLiquidity) revert InsufficientLiquidity();

        amountOut -= amountOut.mulWadDown(tradingFee);
    }

    function tokenPrice() external view returns (uint256 price) {
        price = reserveBase.divWadDown(reserveSale);
    }

    // ======================================== HELPER FUNCTIONS ========================================

    function _subtractFee(uint256 amount) internal view returns (uint256 feeAmount, uint256 remainingAmount) {
        feeAmount = amount.mulWadDown(tradingFee);
        remainingAmount = amount - feeAmount;
    }

    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256) {
        if (amountIn == 0) revert InsufficientAmountIn();
        if (reserveIn == 0 || reserveOut == 0) revert InsufficientLiquidity();

        return (amountIn * reserveOut) / (reserveIn + amountIn);
    }

    function _adjustSaleAmountOut(uint256 amountOut) internal view returns (uint256) {
        if (block.timestamp >= startTime + PROTECTION_DURATION) return amountOut;

        uint256 reserveSaleAfter = reserveSale - amountOut;
        uint256 reserveSaleMinimum =
            initialReserveSale - initialReserveSale * (block.timestamp - startTime) / PROTECTION_DURATION;

        if (reserveSaleAfter < reserveSaleMinimum) {
            return amountOut * reserveSaleAfter / reserveSaleMinimum * reserveSaleAfter / reserveSaleMinimum;
        }

        return amountOut;
    }
}
