// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-std/interfaces/IERC20.sol";
import "src/CheeseLending.sol";
import "script/exploit/Exploit.sol";
import "src/CheeseLending.sol";
import "src/Cheese.sol";
import "./Cow.s.sol";

import "forge-std/Script.sol";

contract Solve is Script {
    function run() external {
        uint256 playerPrivateKey = vm.envOr("PLAYER", uint256(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80));
        
        address challenge = deploy(vm.addr(playerPrivateKey));

        vm.startBroadcast(playerPrivateKey);

        solve(challenge, vm.addr(playerPrivateKey));

        vm.stopBroadcast();
    }

    function solve(address challengeAddress, address player) internal {
        CheeseLending pool = CheeseLending(challengeAddress);

        Attacker attacker = new Attacker(pool);

        IERC20 gruyere = IERC20(pool.assets(0));
        IERC20 emmental = IERC20(pool.assets(1));

        gruyere.transfer(address(attacker), gruyere.balanceOf(player));
        emmental.transfer(address(attacker), emmental.balanceOf(player));

        attacker.run_exploit();

        bool isSolved = pool.isSolved();
        console.log("Chall solved? ", isSolved);
        assert(isSolved);
    }

    function deploy(address player) internal  returns(address){
        vm.startBroadcast();

        uint256 initialSupply = 0;
        Cheese gruyere = new Cheese(initialSupply, "Gruyere", "GRY");
        Cheese emmental = new Cheese(initialSupply, "Emmental", "ETL");

        CheeseLending cheeseLending = new CheeseLending(player, address(gruyere), address(emmental));

        Cow cow = new Cow(cheeseLending);

        gruyere.mint(player, 100 * 1e18);
        gruyere.mint(address(cow), 10 * 1e18);
        gruyere.dropMint();
        require(gruyere.totalSupply() == 110 * 1e18);

        emmental.mint(player, 100 * 1e18);
        emmental.mint(address(cow), 10 * 1e18);
        emmental.dropMint();

        require(emmental.totalSupply() == 110 * 1e18);

        cow.init(gruyere, emmental);

        address challenge = address(cheeseLending);


        require(emmental.balanceOf(address(cheeseLending))>0);
        require(gruyere.balanceOf(address(cheeseLending))>0);


        vm.stopBroadcast();

        return challenge;
    }


}