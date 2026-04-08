// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {ERC20} from "@solmate/tokens/ERC20.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "@solmate/utils/SafeTransferLib.sol";
import {Tables, Opcodes} from "src/Opcodes.sol";

/// @title ISimpleCallbacks
/// @notice Interface for callbacks.
interface ISimpleCallbacks {
    /**
     * @notice Callback called when a deposit occurs.
     * @dev The callback is called only if data is not empty.
     * @param _assets  The amount of supplied assets.
     * @param _data    Arbitrary data passed to the `flashLoan` function.
     */
    function onFlashLoan(uint256 _assets, bytes calldata _data) external;
}

/// @title ConstantSumPair
/// @notice The ConstantSumPair contract.
contract ConstantSumPair is ERC20, Opcodes {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;

    uint256 public constant MAX_FEE = 0.1e18; // 10%

    address public immutable factory;

    ERC20 public tokenX;
    ERC20 public tokenY;

    uint256 public price;
    uint256 public fee;
    address public feeRecipient;

    uint256 public reserveX;
    uint256 public reserveY;
    uint256 public k;

    constructor(Tables memory tables) ERC20("ConstantSumPair Token", "CSP", 18) Opcodes(tables) {
        factory = msg.sender;
    }

    function initialize(address _tokenX, address _tokenY, uint256 _price, uint256 _fee, address _feeRecipient)
        external
    {
        require(msg.sender == factory, "Not factory");
        require(price == 0, "Already initialized");
        require(_fee <= MAX_FEE, "Fee too large");

        tokenX = ERC20(_tokenX);
        tokenY = ERC20(_tokenY);

        price = _price;
        fee = _fee;
        feeRecipient = _feeRecipient;
    }

    // ========================================= MODIFIERS ========================================

    /**
     * @notice Enforces the x + y = k invariant
     */
    modifier invariant() {
        _;
        require(_gte256(_computeK(reserveX, reserveY), k), "K");
    }

    // ========================================= MUTATIVE FUNCTIONS ========================================

    /**
     * @notice Deposit tokenX and tokenY into the pool for LP tokens.
     *
     * @param amountXIn  The amount of tokenX to deposit.
     * @param amountYIn  The amount of tokenY to deposit.
     */
    function allocate(uint256 amountXIn, uint256 amountYIn) external invariant returns (uint256 shares) {
        uint256 deltaK = _computeK(amountXIn, amountYIn);
        shares = k == 0 ? deltaK : deltaK.mulDivDown(totalSupply, k);

        reserveX += amountXIn;
        reserveY += amountYIn;
        k += deltaK;

        _mint(msg.sender, shares);

        tokenX.safeTransferFrom(msg.sender, address(this), amountXIn);
        tokenY.safeTransferFrom(msg.sender, address(this), amountYIn);
    }

    /**
     * @notice Withdraw tokenX and tokenY from the pool by burning LP tokens.
     *
     * @param amountXOut  The amount of tokenX to withdraw.
     * @param amountYOut  The amount of tokenY to withdraw.
     */
    function deallocate(uint256 amountXOut, uint256 amountYOut) external invariant returns (uint256 shares) {
        uint256 deltaK = _computeK(amountXOut, amountYOut);
        shares = deltaK.mulDivUp(totalSupply, k);

        reserveX -= amountXOut;
        reserveY -= amountYOut;
        k -= deltaK;

        _burn(msg.sender, shares);

        tokenX.safeTransfer(msg.sender, amountXOut);
        tokenY.safeTransfer(msg.sender, amountYOut);
    }

    /**
     * @notice Swap either token for the other.
     *
     * @param swapXForY  Whether the swap is tokenX to tokenY, or vice versa.
     * @param amountIn   The amount of tokens to swap in.
     * @param amountOut  The amount of tokens to swap out.
     */
    function swap(bool swapXForY, uint256 amountIn, uint256 amountOut) external invariant {
        ERC20 tokenIn;
        ERC20 tokenOut;

        uint256 feeAmount = amountIn.mulWadUp(fee);
        uint256 amountInAfterFee = amountIn - feeAmount;

        if (swapXForY) {
            reserveX += amountInAfterFee;
            reserveY -= amountOut;

            (tokenIn, tokenOut) = (tokenX, tokenY);
        } else {
            reserveX -= amountOut;
            reserveY += amountInAfterFee;

            (tokenIn, tokenOut) = (tokenY, tokenX);
        }

        tokenIn.safeTransferFrom(msg.sender, address(this), amountIn);
        tokenIn.safeTransfer(feeRecipient, feeAmount);
        tokenOut.safeTransfer(msg.sender, amountOut);
    }

    /**
     * @notice Flash loan either token from the pool.
     *
     * @param isTokenX  Whether the token to loan is tokenX or tokenY.
     * @param amount    The amount of tokens to loan.
     * @param data      Arbitrary data passed to the callback.
     */
    function flashLoan(bool isTokenX, uint256 amount, bytes calldata data) external invariant {
        ERC20 token = isTokenX ? tokenX : tokenY;
        token.safeTransfer(msg.sender, amount);

        ISimpleCallbacks(msg.sender).onFlashLoan(amount, data);

        token.safeTransferFrom(msg.sender, address(this), amount);
    }

    // ========================================= HELPERS ========================================

    function _computeK(uint256 amountX, uint256 amountY) internal view returns (uint256) {
        return _add256(amountX, amountY.divWadDown(price));
    }
}
