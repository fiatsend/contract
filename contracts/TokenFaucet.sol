// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenFaucet {
    IERC20 public tether;
    IERC20 public fsend;
    IERC20 public ghsfiat;

    uint256 public constant REQUEST_AMOUNT = 100 * 10**18; // Example amount
    uint256 public constant COOLDOWN_TIME = 24 hours;
    mapping(address => uint256) public lastRequestTime;

    constructor(address _tether, address _fsend, address _ghsfiat) {
        tether = IERC20(_tether);
        fsend = IERC20(_fsend);
        ghsfiat = IERC20(_ghsfiat);
    }

    function requestTokens() public {
        require(block.timestamp >= lastRequestTime[msg.sender] + COOLDOWN_TIME, "Cooldown period not met");

        // Request all available tokens
        _requestToken(tether);
        _requestToken(fsend);
        _requestToken(ghsfiat);

        lastRequestTime[msg.sender] = block.timestamp;
    }

    function _requestToken(IERC20 token) internal {
        require(token.balanceOf(address(this)) >= REQUEST_AMOUNT, "Insufficient tokens in faucet");
        token.transfer(msg.sender, REQUEST_AMOUNT);
    }

}