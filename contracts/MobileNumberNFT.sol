// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ECDSA } from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract Mobilenumbernft is Initializable, ERC721URIStorageUpgradeable, Ownable2StepUpgradeable, AccessControlUpgradeable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 private _tokenIdCounter;

    mapping(bytes32 => address) private mobileToWallet;
    mapping(address => uint256) public walletToToken;

    event MobileRegistered(address indexed wallet, bytes32 indexed mobileHash, uint256 tokenId);

    function initialize() public initializer {
        __ERC721_init("Fiatsend Identity", "FSID");
        __Ownable_init(msg.sender);
        __Ownable2Step_init();
        __AccessControl_init();

        // Set up roles
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(REGISTRAR_ROLE, msg.sender);
    }

    /// @notice Register a mobile number by proving ownership of it via a signature
    /// @param mobileNumber The plain text mobile number
    /// @param metadataURI The URI of the NFT metadata
    /// @param signature The ECDSA signature of the mobile number by the caller
    function registerMobile(
        string calldata mobileNumber,
        string calldata metadataURI,
        bytes calldata signature
    ) external onlyRole(REGISTRAR_ROLE) {
        bytes32 mobileHash = keccak256(abi.encodePacked(mobileNumber));

        require(mobileToWallet[mobileHash] == address(0), "Mobile number already registered");

        // Ensure the mobile number is signed by msg.sender
        bytes32 ethSignedHash = mobileHash.toEthSignedMessageHash();
        require(ethSignedHash.recover(signature) == msg.sender, "Invalid signature");

        uint256 newTokenId = ++_tokenIdCounter;

        // Update state variables first (checks-effects-interactions pattern)
        mobileToWallet[mobileHash] = msg.sender;
        walletToToken[msg.sender] = newTokenId;
        _setTokenURI(newTokenId, metadataURI);

        // Emit event before external call
        emit MobileRegistered(msg.sender, mobileHash, newTokenId);

        // External call last
        _safeMint(msg.sender, newTokenId);
    }

    /// @notice Look up wallet by mobile number
    /// @param mobileNumber The plaintext mobile number
    function getWalletByMobile(string calldata mobileNumber) external view returns (address) {
        bytes32 mobileHash = keccak256(abi.encodePacked(mobileNumber));
        return mobileToWallet[mobileHash];
    }

    /// @notice Look up NFT token ID by wallet
    function getTokenByWallet(address wallet) external view returns (uint256) {
        return walletToToken[wallet];
    }

    /// @notice Grant registrar role to an address
    /// @param registrar Address to grant registrar role
    function grantRegistrarRole(address registrar) external onlyRole(ADMIN_ROLE) {
        grantRole(REGISTRAR_ROLE, registrar);
    }

    /// @notice Revoke registrar role from an address
    /// @param registrar Address to revoke registrar role
    function revokeRegistrarRole(address registrar) external onlyRole(ADMIN_ROLE) {
        revokeRole(REGISTRAR_ROLE, registrar);
    }

    /// @notice Grant admin role to an address
    /// @param admin Address to grant admin role
    function grantAdminRole(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(ADMIN_ROLE, admin);
    }

    /// @notice Revoke admin role from an address
    /// @param admin Address to revoke admin role
    function revokeAdminRole(address admin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        revokeRole(ADMIN_ROLE, admin);
    }
}
