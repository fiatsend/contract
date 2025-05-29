// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract FiatsendAccountService is ERC721URIStorageUpgradeable, UUPSUpgradeable, OwnableUpgradeable {
    mapping(address => uint256) public userTokenId;

    function initialize() public initializer {
        __ERC721_init("Fiatsend Account Service", "FAS");
        __Ownable_init(msg.sender);
    }

    function mintFiatsendNFT(string memory encryptedPhone) external {
        require(userTokenId[msg.sender] == 0, "User already registered");

        uint256 tokenId = uint256(keccak256(abi.encodePacked(encryptedPhone, msg.sender)));
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, encryptedPhone);

        userTokenId[msg.sender] = tokenId;
    }

    function getEncryptedPhoneNumber(uint256 tokenId) external view returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return tokenURI(tokenId);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
