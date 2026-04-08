// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Challenge } from "src/Challenge.sol";
import { RedMemory } from "src/RedMemory.sol";
import { Script } from "forge-std/Script.sol";
import { Remembrance } from "../src/test/RedMemoryTest.t.sol";

contract SolveLocal is Script {
    RedMemory public redMemory;
    function run() external {
        vm.startBroadcast();
        Remembrance _remembrance = new Remembrance();
        Challenge _challenge = Challenge(0xc8e9126e983cE0fA645156447df3dC926B8C2D1e);
        redMemory = _challenge.redMemory();
        redMemory.cast(address(_remembrance));
        vm.stopBroadcast();
    }
}