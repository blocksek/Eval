// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

import {Owned} from "@solmate/auth/Owned.sol";
import {ERC20} from "@solmate/tokens/ERC20.sol";

contract RegularToken is ERC20, Owned {
    constructor(string memory _name, string memory _symbol, uint8 _decimals)
        ERC20(_name, _symbol, _decimals)
        Owned(msg.sender)
    {}

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}

contract NoRevertOnFailureToken is RegularToken {
    constructor(string memory _name, string memory _symbol, uint8 _decimals) RegularToken(_name, _symbol, _decimals) {}

    function transfer(address to, uint256 amount) public override returns (bool) {
        if (balanceOf[msg.sender] < amount) return false;

        return super.transfer(to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        if (allowance[from][msg.sender] < amount || balanceOf[from] < amount) return false;

        return super.transferFrom(from, to, amount);
    }
}
