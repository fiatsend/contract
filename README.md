# Fiatsend Smart Contracts

This repository contains the smart contracts that power the Fiatsend protocol.

## Overview

The main contract `MobileNumberNFT` is an ERC721 token that:
- Allows users to register their mobile numbers as NFTs
- Securely stores mobile number hashes on-chain
- Maps mobile numbers to wallet addresses
- Provides a way to look up wallet addresses by mobile number

## Security Features

- Mobile numbers are hashed before being stored on-chain
- The original mobile numbers are never exposed in transactions
- Uses OpenZeppelin's upgradeable contracts for future improvements
- Implements proper access control through Ownable pattern

## Development

This project uses Hardhat for development, testing, and deployment.

### Prerequisites

- Node.js (v14+)
- npm or yarn

### Installation

```bash
npm install
# or
yarn install
```

### Testing

```bash
# Run all tests
npx hardhat test

# Run tests with gas reporting
REPORT_GAS=true npx hardhat test
```

### Deployment

```bash
# Deploy using Hardhat Ignition
npx hardhat ignition deploy ./ignition/modules/MobileNumberNFT.js
```

## Contract Architecture

The main contract `MobileNumberNFT.sol` is built using:
- OpenZeppelin's ERC721URIStorageUpgradeable for NFT functionality
- OpenZeppelin's OwnableUpgradeable for access control
- OpenZeppelin's Initializable for upgradeable contract pattern

## License

MIT
