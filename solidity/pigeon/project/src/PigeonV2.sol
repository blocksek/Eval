// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";

import "./SimpleSafe.sol";

contract PigeonV2 is Initializable, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    SimpleSafe public safe;

    address public keeper;
    address public carrier;

    mapping(address => uint256) public carryAllowance;

    error Unauthorized();
    error ZeroAddress();
    error NotBanded();
    error CarryLimitExceeded();
    error AlreadyInFlight();
    error FailedDelivery();

    modifier onlyKeeper() {
        if (msg.sender != keeper) revert Unauthorized();
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize() external reinitializer(2) {
        __Pausable_init();
        carrier = address(100);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function band(address pigeon, uint256 carryLimit) external onlyKeeper whenNotPaused {
        if (pigeon == address(0)) revert ZeroAddress();
        carryAllowance[pigeon] = carryLimit;
    }

    function release(bytes calldata _msg) external whenNotPaused {
        (address pigeon, address dest, uint256 value, bytes memory cd) =
            abi.decode(_msg, (address, address, uint256, bytes));

        if (carryAllowance[pigeon] == 0) revert NotBanded();
        if (value > carryAllowance[pigeon]) revert CarryLimitExceeded();
        if (carrier != address(100)) revert AlreadyInFlight();

        delete carryAllowance[pigeon];

        carrier = pigeon;
        (bool success,) = dest.call{value: value}(cd);
        carrier = address(100);

        if (!success) revert FailedDelivery();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    receive() external payable {}
}
