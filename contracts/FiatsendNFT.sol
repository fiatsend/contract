// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FiatsendNFT is ERC721URIStorage, Ownable {
    uint256 public tokenCounter; // Tracks the number of NFTs minted

    // Mapping from token ID to encrypted phone number
    mapping(uint256 => string) private encryptedPhoneNumbers;

  constructor() ERC721("FiatsendNFT", "FSNFT") Ownable(msg.sender) {
    tokenCounter = 0;
}
    /**
     * @notice Mints an NFT linked to an encrypted phone number.
     * @param to The address receiving the NFT.
     * @param tokenURI The metadata URI for the NFT.
     * @param encryptedPhoneNumber The encrypted phone number to associate with the NFT.
     */
    function mintFiatsendNFT(
        address to,
        string memory tokenURI,
        string memory encryptedPhoneNumber
    ) external {
        uint256 newTokenId = tokenCounter;
        _safeMint(to, newTokenId); // Mint the NFT
        _setTokenURI(newTokenId, tokenURI); // Set metadata
        encryptedPhoneNumbers[newTokenId] = encryptedPhoneNumber; // Store the encrypted phone number
        tokenCounter += 1;
    }

    /**
     * @notice Retrieves the encrypted phone number linked to a token ID.
     * @param tokenId The ID of the NFT.
     * @return The encrypted phone number.
     */
    function getEncryptedPhoneNumber(uint256 tokenId) external view returns (string memory) {
        return encryptedPhoneNumbers[tokenId];
    }

    /**
     * @notice Burns an NFT and removes its associated data.
     * @param tokenId The ID of the NFT to burn.
     */
    function burnNFT(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender || getApproved(tokenId) == msg.sender || isApprovedForAll(ownerOf(tokenId), msg.sender), "FiatsendNFT: Not owner or approved");
        _burn(tokenId);
        delete encryptedPhoneNumbers[tokenId]; // Remove the associated encrypted phone number
    }
}
