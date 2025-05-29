// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract FiatsendAccount {
    // --- Struct Definitions ---

    // Structure to store account details
    struct Account {
        address userAddress;
        uint256 balance;
        bool isKYCVerified;
    }

    // --- State Variables ---
    mapping(address => Account) private accounts;
    address public admin;

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    modifier onlyVerifiedUser() {
        require(accounts[msg.sender].isKYCVerified, "KYC not verified");
        _;
    }

    // --- Events ---
    event AccountRegistered(address indexed user);
    event DepositMade(address indexed user, uint256 amount);
    event WithdrawalMade(address indexed user, uint256 amount);
    event KYCApproved(address indexed user);
    event KYCRevoked(address indexed user);

    // --- Constructor ---
    constructor() {
        admin = msg.sender;
    }

    // --- Core Functions ---

    // 1. Register a new account
    function registerAccount() external {
        require(accounts[msg.sender].userAddress == address(0), "Account already exists");
        accounts[msg.sender] = Account(msg.sender, 0, false);
        emit AccountRegistered(msg.sender);
    }

    // 2. Deposit fiat (tokenized in contract)
    function depositFiat(uint256 amount) external onlyVerifiedUser {
        require(amount > 0, "Deposit amount must be greater than zero");
        accounts[msg.sender].balance += amount;
        emit DepositMade(msg.sender, amount);
    }

    // 3. Withdraw fiat (burn token equivalent)
    function withdrawFiat(uint256 amount) external onlyVerifiedUser {
        require(amount > 0, "Withdrawal amount must be greater than zero");
        require(accounts[msg.sender].balance >= amount, "Insufficient balance");

        accounts[msg.sender].balance -= amount;
        emit WithdrawalMade(msg.sender, amount);
    }

    // 4. Check balance
    function getBalance() external view returns (uint256) {
        return accounts[msg.sender].balance;
    }

    // 5. Approve KYC for user (Admin-only)
    function approveKYC(address user) external onlyAdmin {
        require(accounts[user].userAddress != address(0), "Account does not exist");
        accounts[user].isKYCVerified = true;
        emit KYCApproved(user);
    }

    // 6. Revoke KYC for user (Admin-only)
    function revokeKYC(address user) external onlyAdmin {
        require(accounts[user].userAddress != address(0), "Account does not exist");
        accounts[user].isKYCVerified = false;
        emit KYCRevoked(user);
    }
}
