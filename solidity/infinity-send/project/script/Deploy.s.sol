// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {CTFDeployer} from "forge-ctf/CTFDeployer.sol";
import {Challenge} from "src/Challenge.sol";

contract Deploy is CTFDeployer {
    function deploy(address system, address player) internal override returns (address challenge) {
        vm.startBroadcast(system);
        challenge = _deploy(player);
        vm.stopBroadcast();
    }

    function _deploy(address player) public returns (address challenge) {
        challenge = address(new Challenge(player));
    }
}
