// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MobileNumberNFT is Initializable, ERC721URIStorageUpgradeable, OwnableUpgradeable {
    uint256 private _tokenIdCounter;
    mapping(bytes32 => address) public mobileToWallet;
    mapping(address => uint256) public walletToToken;

    event MobileRegistered(address indexed wallet, bytes32 mobileHash, uint256 tokenId);

    // ✅ Instead of a constructor, we use initialize()
    function initialize() public initializer {
        __ERC721_init("Fiatsend Identity", "FSID");
        __Ownable_init(msg.sender);  // ✅ Set initial owner
    }

    function registerMobile(bytes32 mobileHash, string memory metadataURI) external {
        require(mobileToWallet[mobileHash] == address(0), "Mobile number already registered");

        uint256 newTokenId = _tokenIdCounter + 1;
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, metadataURI);

        mobileToWallet[mobileHash] = msg.sender;
        walletToToken[msg.sender] = newTokenId;
        _tokenIdCounter++;

        emit MobileRegistered(msg.sender, mobileHash, newTokenId);
    }

    function getWalletByMobile(string memory mobileNumber) external view returns (address) {
        bytes32 mobileHash = keccak256(abi.encodePacked(mobileNumber));
        return mobileToWallet[mobileHash];
    }
}
