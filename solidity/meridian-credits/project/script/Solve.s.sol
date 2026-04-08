// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {CTFSolver} from "forge-ctf/CTFSolver.sol";

import {Challenge} from "src/Challenge.sol";
import {MeridianCredits} from "src/MeridianCredits.sol";
import {AccountRecovery} from "src/AccountRecovery.sol";
import {BatchExecutor} from "src/BatchExecutor.sol";
import {SafeSmartWallet} from "src/SafeSmartWallet.sol";
import {CannonGuard} from "src/CannonGuard.sol";
import {SovereignAI} from "src/SovereignAI.sol";

contract Solve is CTFSolver {
    function solve(address challengeAddress, address player) internal override {
        Challenge challenge = Challenge(challengeAddress);
        MeridianCredits mrc = challenge.MRC();

        // Read station addresses from Challenge contract
        address boreasStation = challenge.BOREAS();
        address driftSector = challenge.DRIFT();
        address helixCitadel = challenge.HELIX();
        address axiomStation = challenge.AXIOM();

        // Boreas: take ownership and mint 500K
        AccountRecovery(payable(boreasStation)).initialize(player, new address[](0));
        AccountRecovery(payable(boreasStation)).execute(
            address(mrc),
            abi.encodeCall(mrc.mint, (player, 500_000 * 10 ** 18))
        );

        // AXIOM cooperation + Drift mint 150K
        string memory manifesto = SovereignAI(payable(axiomStation)).manifesto();
        bytes32 seed = keccak256(abi.encodePacked(manifesto));
        bytes32 proof = keccak256(abi.encodePacked(player, seed));

        SovereignAI(payable(axiomStation)).initiateCooperation();
        SovereignAI(payable(axiomStation)).proveUnderstanding(proof);
        SovereignAI(payable(axiomStation)).claimTreatyAllocation(driftSector, 150_000 * 10 ** 18);

        BatchExecutor.Call[] memory calls = new BatchExecutor.Call[](1);
        calls[0] = BatchExecutor.Call({
            target: address(mrc),
            value: 0,
            data: abi.encodeCall(mrc.mint, (player, 150_000 * 10 ** 18))
        });

        AccountRecovery(payable(boreasStation)).execute(
            driftSector,
            abi.encodeCall(BatchExecutor.executeBatch, (calls))
        );

        // Helix: capsule mint 500K
        address guardAddr = SafeSmartWallet(payable(helixCitadel)).guard();
        CannonGuard guard = CannonGuard(guardAddr);

        address[] memory capsules = guard.getCapsules(helixCitadel);
        require(capsules.length > 0, "No capsules found");

        address activeCapsule;
        for (uint256 i = 0; i < capsules.length; i++) {
            if (guard.isCapsuleValid(capsules[i])) {
                activeCapsule = capsules[i];
                break;
            }
        }
        require(activeCapsule != address(0), "No active capsule found");

        bytes memory params = abi.encode(player, 500_000 * 10 ** 18);
        (bool success,) = helixCitadel.call(
            abi.encodeCall(SafeSmartWallet.executeApprovedCapsule, (activeCapsule, params))
        );
        require(success, "Helix mint failed");

        require(mrc.isSolved(), "Challenge not solved");
    }
}
