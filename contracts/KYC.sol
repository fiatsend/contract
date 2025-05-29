// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract KYC {
    // --- State Variables ---
    address public admin;
    mapping(address => bool) private verifiedUsers;

    // --- Events ---
    event KYCApproved(address indexed user);
    event KYCRevoked(address indexed user);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
    }

    // --- Functions ---

    // Approve KYC for a user
    function approveKYC(address user) external onlyAdmin {
        verifiedUsers[user] = true;
        emit KYCApproved(user);
    }

    // Revoke KYC for a user
    function revokeKYC(address user) external onlyAdmin {
        verifiedUsers[user] = false;
        emit KYCRevoked(user);
    }

    // Check if a user is KYC verified
    function isVerified(address user) external view returns (bool) {
        return verifiedUsers[user];
    }
}
