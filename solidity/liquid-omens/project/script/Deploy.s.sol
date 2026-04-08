// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-ctf/CTFDeployer.sol";

import "src/BadDebtMarket.sol";
import "src/Challenge.sol";
import "src/DirectivePreviewLib.sol";
import "src/LiquidationEngine.sol";
import "src/LiquidationVenue.sol";
import "src/MockERC20.sol";

contract Deploy is CTFDeployer {
    address private constant BORROWER = address(0xB0B);
    uint256 private constant KEEPER_PRIVATE_KEY =
        0xA11CE0A11CE0A11CE0A11CE0A11CE0A11CE0A11CE0A11CE0A11CE0A11CE0A11;
    uint256 private constant POSITION_COLLATERAL = 160 ether;
    uint256 private constant POSITION_DEBT = 100 ether;
    uint256 private constant ENGINE_FLOAT = POSITION_DEBT;
    uint256 private constant VENUE_RESERVE = 1_000 ether;

    function deploy(address system, address player) internal override returns (address challenge) {
        vm.startBroadcast(system);

        MockERC20 collateralToken = new MockERC20("Shadow Margin", "sMARGIN");
        MockERC20 quoteToken = new MockERC20("Omens Dollar", "oUSD");

        BadDebtMarket market = new BadDebtMarket(collateralToken, quoteToken);
        LiquidationVenue venue = new LiquidationVenue(collateralToken, quoteToken, VENUE_RESERVE);
        LiquidationEngine engine = new LiquidationEngine(market, venue, quoteToken, vm.addr(KEEPER_PRIVATE_KEY), player);

        market.setEngine(address(engine));
        venue.setEngine(address(engine));

        collateralToken.mint(address(market), POSITION_COLLATERAL);
        quoteToken.mint(address(engine), ENGINE_FLOAT);
        quoteToken.mint(address(venue), VENUE_RESERVE);
        market.seedPosition(BORROWER, POSITION_COLLATERAL, POSITION_DEBT);

        bytes memory signature = _prepareSignature(address(engine));

        challenge = address(new Challenge(player, collateralToken, quoteToken, market, venue, engine));
        engine.recordDirective(signature);

        vm.stopBroadcast();
    }

    function _prepareSignature(address engineAddress)
        private
        view
        returns (bytes memory signature)
    {
        DirectivePreviewLib.DirectivePreview memory preview = DirectivePreviewLib.DirectivePreview({
            directiveKind: DirectivePreviewLib.liquidationDirectiveKind(),
            commandHash: keccak256(abi.encodeCall(LiquidationVenue.highlyProfitableTradingStrategy, ()))
        });

        bytes32 digest = DirectivePreviewLib.digest(preview, engineAddress);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(KEEPER_PRIVATE_KEY, digest);
        signature = abi.encodePacked(r, s, v);
    }
}
