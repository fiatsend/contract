// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

interface IForwarder {
    function execute(address to, uint256 value, bytes calldata data) external;
}

contract SmartWallet is Initializable, OwnableUpgradeable {
    IForwarder public trustedForwarder;

    event TransactionExecuted(address indexed to, uint256 value, bytes data);

    function initialize(address _owner, address _trustedForwarder) public initializer {
        __Ownable_init(_owner);
        trustedForwarder = IForwarder(_trustedForwarder);
    }

    function executeTransaction(address to, uint256 value, bytes calldata data) external onlyOwner {
        (bool success, ) = to.call{value: value}(data);
        require(success, "Transaction failed");

        emit TransactionExecuted(to, value, data);
    }

    function setTrustedForwarder(address _trustedForwarder) external onlyOwner {
        trustedForwarder = IForwarder(_trustedForwarder);
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return address(trustedForwarder) == forwarder;
    }
}
