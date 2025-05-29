// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./SmartWallet.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract SmartWalletFactory {
    address public immutable walletImplementation;
    mapping(address => address) public userWallets;

    event WalletCreated(address indexed owner, address wallet);

    constructor(address _walletImplementation) {
        walletImplementation = _walletImplementation;
    }

    function createWallet(address _trustedForwarder) external {
        require(userWallets[msg.sender] == address(0), "User already has a wallet");

        // Clone the wallet (minimal proxy pattern)
        address wallet = Clones.clone(walletImplementation);

        // Initialize the wallet
        SmartWallet(payable(wallet)).initialize(msg.sender, _trustedForwarder);

        // Store the wallet
        userWallets[msg.sender] = wallet;

        emit WalletCreated(msg.sender, wallet);
    }

    function getUserWallet(address user) external view returns (address) {
        return userWallets[user];
    }
}
