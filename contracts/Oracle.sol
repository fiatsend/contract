// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract Oracle {
    // --- State Variables ---
    address public admin;
    uint256 public fiatToCryptoRate; // Rate from fiat to crypto, multiplied by 1e18 for precision

    // --- Events ---
    event RateUpdated(uint256 newRate);

    // --- Modifiers ---
    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    // --- Constructor ---
    constructor(uint256 initialRate) {
        admin = msg.sender;
        fiatToCryptoRate = initialRate;
    }

    // --- Functions ---

    // Update the fiat-to-crypto exchange rate
    function updateRate(uint256 newRate) external onlyAdmin {
        require(newRate > 0, "Rate must be positive");
        fiatToCryptoRate = newRate;
        emit RateUpdated(newRate);
    }

    // Get the current fiat-to-crypto rate
    function getRate() external view returns (uint256) {
        return fiatToCryptoRate;
    }
}
