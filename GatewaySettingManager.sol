// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";

abstract contract GatewaySettingManager is Ownable2StepUpgradeable {
    mapping(address => uint8) internal _isTokenSupported;

    event TokenSupported(address indexed token);
    event TokenUnsupported(address indexed token);

    function supportToken(address token) external onlyOwner {
        _isTokenSupported[token] = 1;
        emit TokenSupported(token);
    }

    function removeToken(address token) external onlyOwner {
        _isTokenSupported[token] = 0;
        emit TokenUnsupported(token);
    }
}
