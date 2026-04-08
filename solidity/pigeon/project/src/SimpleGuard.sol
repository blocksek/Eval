// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SimpleGuard {
    address public owner;
    address public compliance;
    mapping(address => bool) public pendingCallers;
    mapping(address => bool) public approvedCallers;
    mapping(address => uint256) public complianceCount;
    mapping(bytes => bool) public usedSigs;

    error MustBeApproved();
    error MustBePending();
    error OnlyOwner();
    error NotCompliance();
    error SignatureAlreadyUsed();
    error InvalidLength();

    event PendingCallerApproved(address);
    event ApprovedCaller(address);

    constructor(address _compliance) {
        owner = msg.sender;
        compliance = _compliance;
    }

    function approvePendingCaller(address _caller) external {
        if (msg.sender != owner) revert OnlyOwner();
        pendingCallers[_caller] = true;
        emit PendingCallerApproved(_caller);
    }

    function confirmPendingCaller(address _caller, bytes calldata _signature, bytes32 _message) external {
        if (!pendingCallers[_caller]) revert MustBeApproved();

        if (usedSigs[_signature]) revert SignatureAlreadyUsed();

        if (_signature.length != 65) revert InvalidLength();

        bytes32 _r = bytes32(_signature[0:32]);
        bytes32 _s = bytes32(_signature[32:64]);
        uint8 _v = uint8(_signature[64]);

        address _signer = ecrecover(_message, _v, _r, _s);

        if (_signer != compliance) revert NotCompliance();
        
        usedSigs[_signature] = true;

        complianceCount[_caller]++;

        if (complianceCount[_caller] == 3) {
            approvedCallers[_caller] = true;
            emit ApprovedCaller(_caller);
        }
    }

    function canExecute(address _caller) external returns (bool) {
        if (!approvedCallers[_caller]) revert MustBeApproved();
        approvedCallers[_caller] = false;
        complianceCount[_caller] = 0;
        return true;
    }
}
