// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20; // ✅ L001 & L002: Fixed pragma

import "@openzeppelin/contracts/access/Ownable.sol"; // 🔐 Production-grade access control

contract FxOracle is Ownable {
    uint256 public rate;
    uint256 public lastUpdated;
    uint256 public immutable staleTimeout; // ⏰ Define max time before data is considered stale

    event RateUpdated(uint256 rate, uint256 timestamp, address indexed updater); // ✅ I002, G005
    event OracleInitialized(address indexed owner); // ✅ I002

    constructor(uint256 _staleTimeout, address initialOwner) Ownable(initialOwner) payable {
        require(_staleTimeout > 0, "Invalid timeout");
        staleTimeout = _staleTimeout;
        emit OracleInitialized(initialOwner);
    }

    function updateRate(uint256 _rate) external onlyOwner {
        require(_rate > 0, "Rate must be > 0");

        // ✅ G001, G002: Avoid wasteful writes
        if (_rate != rate) {
            rate = _rate;
        }

        lastUpdated = block.timestamp; // ✅ I001
        emit RateUpdated(_rate, block.timestamp, msg.sender);
    }

    function getRate() external view returns (uint256) {
        require(!isStale(), "Rate is stale");
        return rate;
    }

    function isStale() public view returns (bool) {
        return block.timestamp > lastUpdated + staleTimeout;
    }
}
