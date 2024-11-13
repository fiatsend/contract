// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./KYC.sol";
import "./Oracle.sol";

contract Exchange {
    // --- State Variables ---
    KYC private kycContract;
    Oracle private oracleContract;
    address public admin;

    mapping(address => uint256) public userBalances;

    // --- Events ---
    event FiatExchangedForCrypto(address indexed user, uint256 fiatAmount, uint256 cryptoAmount);
    event CryptoExchangedForFiat(address indexed user, uint256 cryptoAmount, uint256 fiatAmount);

    // --- Modifiers ---
    modifier onlyVerifiedUser() {
        require(kycContract.isVerified(msg.sender), "User not KYC verified");
        _;
    }

    // --- Constructor ---
    constructor(address _kycAddress, address _oracleAddress) {
        kycContract = KYC(_kycAddress);
        oracleContract = Oracle(_oracleAddress);
        admin = msg.sender;
    }

    // --- Core Functions ---

    // Convert fiat to crypto based on the oracle rate
    function exchangeFiatToCrypto(uint256 fiatAmount) external onlyVerifiedUser {
        uint256 rate = oracleContract.getRate();
        uint256 cryptoAmount = (fiatAmount * 1e18) / rate; // Adjust for precision

        // Update user balance with crypto
        userBalances[msg.sender] += cryptoAmount;

        emit FiatExchangedForCrypto(msg.sender, fiatAmount, cryptoAmount);
    }

    // Convert crypto to fiat based on the oracle rate
    function exchangeCryptoToFiat(uint256 cryptoAmount) external onlyVerifiedUser {
        uint256 rate = oracleContract.getRate();
        uint256 fiatAmount = (cryptoAmount * rate) / 1e18; // Adjust for precision

        require(userBalances[msg.sender] >= cryptoAmount, "Insufficient crypto balance");

        // Deduct crypto balance and process fiat equivalent
        userBalances[msg.sender] -= cryptoAmount;

        emit CryptoExchangedForFiat(msg.sender, cryptoAmount, fiatAmount);
    }

    // Get user crypto balance
    function getCryptoBalance() external view returns (uint256) {
        return userBalances[msg.sender];
    }
}
