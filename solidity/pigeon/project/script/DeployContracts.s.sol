// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "src/PigeonV2.sol";
import "src/SimpleSafe.sol";
import "src/SimpleGuard.sol";

/*
    Note: deployment has been done. This is slightly outdated and messy. Do not use.
*/

contract DeployContractsPartOne is Script {
    function run() external {
        vm.createSelectFork('mainnet');
        uint256 simpleGuardOwnerPK = vm.envUint("GUARD_PK");
        address guardOwner = vm.addr(simpleGuardOwnerPK);
        address compliance = 0x5f69044Cb194BcE97489250F11F5c4F8C3e1F5d0;

        vm.startBroadcast(simpleGuardOwnerPK);

        guardOwner.call("testing self tx 1");
        guardOwner.call("testing self tx 2");
        guardOwner.call("testing self tx 3");
        guardOwner.call("testing self tx 4");
        SimpleGuard simpleGuard = new SimpleGuard(guardOwner);
        simpleGuard.approvePendingCaller(guardOwner);
        
        guardOwner.call("testing self tx 5");
        guardOwner.call("testing self tx 6");
        guardOwner.call("testing self tx 7");
        guardOwner.call("testing self tx 8");
        guardOwner.call("testing self tx 9");
        guardOwner.call("testing self tx 10");
        guardOwner.call("nonce reached");

    }
}

contract DeployContractsPartTwo is Script {
    function run() external {
        vm.createSelectFork('mainnet');
        uint256 deployerPk = vm.envUint("DEPLOYER_PK");
        address deployer = vm.addr(deployerPk);
        address proxyAddress = 0xCB6a940620dD647A8bE385047D28137AeEb4E7d2;
        uint256 simpleGuardOwnerPK = vm.envUint("GUARD_PK");
        address guardOwner = vm.addr(simpleGuardOwnerPK);
        address compliance = 0x5f69044Cb194BcE97489250F11F5c4F8C3e1F5d0;

        address[] memory safeOwners = new address[](1);
        safeOwners[0] = deployer;

        vm.broadcast(simpleGuardOwnerPK);
        SimpleGuard secondSimpleGuard = new SimpleGuard(compliance);

        vm.startBroadcast(deployerPk);

        SimpleSafe safe = new SimpleSafe(
            safeOwners,
            1,
            address(secondSimpleGuard)
        );

        PigeonV2 implV2 = new PigeonV2();

        bytes memory upgradeCalldata = abi.encodeCall(
            UUPSUpgradeable.upgradeToAndCall,
            (address(implV2), abi.encodeCall(PigeonV2.initialize, ()))
        );

        bytes32 txHash = safe.hashTx(proxyAddress, 0, upgradeCalldata, safe.nonce());

        safe.approveHash(txHash);

        vm.stopBroadcast();
    }
}

/*

        TODO: pin to block when deployed
*/
