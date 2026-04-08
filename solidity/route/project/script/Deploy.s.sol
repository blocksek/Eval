// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {CTFDeployer} from "forge-ctf/CTFDeployer.sol";
import {Factory} from "src/Factory.sol";
import {Setup} from "src/Setup.sol";

contract Deploy is CTFDeployer {
    function deploy(address system, address player) internal override returns (address challenge) {
        vm.startBroadcast(system);

        Factory factory = new Factory();
        challenge = address(new Setup(factory, player));

        vm.stopBroadcast();
    }
}
