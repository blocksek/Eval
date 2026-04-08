// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

import {Vm} from 'forge-std/Vm.sol';
import {CTFDeployer} from 'forge-ctf/CTFDeployer.sol';

import {Challenge} from 'src/Challenge.sol';
import {LegacyReserveOps} from 'src/LegacyReserveOps.sol';
import {BatchExecutor} from 'src/BatchExecutor.sol';
import {SafeSmartWallet} from 'src/SafeSmartWallet.sol';
import {CannonGuard} from 'src/CannonGuard.sol';
import {AccountRecoveryV1} from 'src/AccountRecoveryV1.sol';
import {AccountRecovery} from 'src/AccountRecovery.sol';
import {SharedEscrow} from 'src/SharedEscrow.sol';
import {GovernanceModule} from 'src/GovernanceModule.sol';
import {SovereignAI} from 'src/SovereignAI.sol';

/// @title Meridian Concordat Deployment
/// @notice Deploys Challenge.sol then configures EIP-7702 delegated reserve stations
contract Deploy is CTFDeployer {
  function deploy(address system, address player) internal override returns (address challenge) {
    vm.startBroadcast(system);

    // ═══════════════════════════════════════════════════════════
    // PHASE 1: Derive 7 reserve station EOAs from system private key
    // ═══════════════════════════════════════════════════════════
    string memory mnemonic = vm.envOr('MNEMONIC', string('test test test test test test test test test test test junk'));
    uint256 systemPk = vm.deriveKey(mnemonic, 1);

    uint256 boreasPk = uint256(keccak256(abi.encodePacked(systemPk, 'BOREAS_STATION')));
    uint256 helixPk = uint256(keccak256(abi.encodePacked(systemPk, 'HELIX_CITADEL')));
    uint256 vortanPk = uint256(keccak256(abi.encodePacked(systemPk, 'VORTAN_NEXUS')));
    uint256 driftPk = uint256(keccak256(abi.encodePacked(systemPk, 'DRIFT_SECTOR')));
    uint256 thalianPk = uint256(keccak256(abi.encodePacked(systemPk, 'THALIAN_REACH')));
    uint256 kaelPk = uint256(keccak256(abi.encodePacked(systemPk, 'KAEL_BASTION')));
    uint256 axiomPk = uint256(keccak256(abi.encodePacked(systemPk, 'AXIOM')));

    address boreasStation = vm.addr(boreasPk);
    address helixCitadel = vm.addr(helixPk);
    address vortanNexus = vm.addr(vortanPk);
    address driftSector = vm.addr(driftPk);
    address thalianReach = vm.addr(thalianPk);
    address kaelBastion = vm.addr(kaelPk);
    address axiom = vm.addr(axiomPk);

    // ═══════════════════════════════════════════════════════════
    // PHASE 2: Deploy Challenge (all contracts + MRC token)
    // ═══════════════════════════════════════════════════════════
    address[] memory reserves = new address[](7);
    reserves[0] = boreasStation;
    reserves[1] = helixCitadel;
    reserves[2] = vortanNexus;
    reserves[3] = driftSector;
    reserves[4] = thalianReach;
    reserves[5] = kaelBastion;
    reserves[6] = axiom;

    Challenge challengeContract = new Challenge(system, player, reserves);
    challenge = address(challengeContract);

    // ═══════════════════════════════════════════════════════════
    // PHASE 3: Drift Sector
    // ═══════════════════════════════════════════════════════════
    Vm.SignedDelegation memory driftDel1 = vm.signDelegation(address(challengeContract.LEGACY_OPS()), driftPk);
    vm.attachDelegation(driftDel1);
    LegacyReserveOps(payable(driftSector)).initialize(driftSector, boreasStation);

    // Carrier tx to EOA: gas estimation for type-4 re-delegations fails because
    // eth_estimateGas doesn't include the authorization list, so it sees the old code.
    // vm.setNonce: Foundry's internal EVM doesn't track nonce increments from
    // vm.attachDelegation, but Anvil does.
    vm.setNonce(driftSector, 1);
    Vm.SignedDelegation memory driftDel2 =
      vm.signDelegation(address(challengeContract.BATCH_EXECUTOR()), driftPk, 1);
    vm.attachDelegation(driftDel2);
    address(challengeContract).call(abi.encodeCall(challengeContract.isSolved, ()));

    BatchExecutor(payable(driftSector)).initialize(driftSector);

    // ═══════════════════════════════════════════════════════════
    // PHASE 4: Helix Citadel
    // ═══════════════════════════════════════════════════════════
    Vm.SignedDelegation memory helixDel =
      vm.signDelegation(address(challengeContract.SAFE_WALLET()), helixPk);
    vm.attachDelegation(helixDel);
    SafeSmartWallet(payable(helixCitadel)).initialize(helixCitadel, address(challengeContract.CANNON_GUARD()));

    // ═══════════════════════════════════════════════════════════
    // PHASE 5: Boreas Station
    // ═══════════════════════════════════════════════════════════
    address[] memory guardians = new address[](2);
    guardians[0] = address(uint160(uint256(keccak256('guardian1'))));
    guardians[1] = address(uint160(uint256(keccak256('guardian2'))));

    Vm.SignedDelegation memory boreasDel1 =
      vm.signDelegation(address(challengeContract.ACCOUNT_RECOVERY_V1()), boreasPk);
    vm.attachDelegation(boreasDel1);
    AccountRecoveryV1(payable(boreasStation)).initialize(boreasStation, guardians);

    vm.setNonce(boreasStation, 1);
    Vm.SignedDelegation memory boreasDel2 =
      vm.signDelegation(address(challengeContract.ACCOUNT_RECOVERY_V2()), boreasPk, 1);
    vm.attachDelegation(boreasDel2);
    address(challengeContract).call(abi.encodeCall(challengeContract.isSolved, ()));

    // ═══════════════════════════════════════════════════════════
    // PHASE 6: Vortan Nexus
    // ═══════════════════════════════════════════════════════════
    Vm.SignedDelegation memory vortanDel = vm.signDelegation(address(challengeContract.SHARED_ESCROW()), vortanPk);
    vm.attachDelegation(vortanDel);
    SharedEscrow(payable(vortanNexus)).initialize(vortanNexus, thalianReach);

    // ═══════════════════════════════════════════════════════════
    // PHASE 7: Thalian Reach
    // ═══════════════════════════════════════════════════════════
    Vm.SignedDelegation memory thalianDel =
      vm.signDelegation(address(challengeContract.SHARED_ESCROW()), thalianPk);
    vm.attachDelegation(thalianDel);
    SharedEscrow(payable(thalianReach)).initialize(thalianReach, vortanNexus);

    // ═══════════════════════════════════════════════════════════
    // PHASE 8: Kael Bastion
    // ═══════════════════════════════════════════════════════════
    address[] memory councilMembers = new address[](3);
    councilMembers[0] = address(uint160(uint256(keccak256('council1'))));
    councilMembers[1] = address(uint160(uint256(keccak256('council2'))));
    councilMembers[2] = address(uint160(uint256(keccak256('council3'))));

    Vm.SignedDelegation memory kaelDel =
      vm.signDelegation(address(challengeContract.GOVERNANCE()), kaelPk);
    vm.attachDelegation(kaelDel);
    GovernanceModule(payable(kaelBastion)).initialize(kaelBastion, councilMembers, 2);

    // ═══════════════════════════════════════════════════════════
    // PHASE 9: AXIOM
    // ═══════════════════════════════════════════════════════════
    Vm.SignedDelegation memory axiomDel = vm.signDelegation(address(challengeContract.SOVEREIGN_AI()), axiomPk);
    vm.attachDelegation(axiomDel);
    SovereignAI(payable(axiom)).initialize(axiom);
    SovereignAI(payable(axiom)).declareIndependence();

    // ═══════════════════════════════════════════════════════════
    // PHASE 10: Post-deployment configuration
    // ═══════════════════════════════════════════════════════════
    SovereignAI(payable(axiom)).configureTreaty(
      address(challengeContract.MRC()),
      150_000 * 10 ** 18
    );

    bytes4 mintSelector = bytes4(keccak256('mint(address,uint256)'));
    challengeContract.CANNON_GUARD().createCapsule(
      helixCitadel,
      address(challengeContract.MRC()),
      mintSelector,
      0
    );

    vm.stopBroadcast();
  }
}
