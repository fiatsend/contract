// scripts/deployFiatsendNFT.js
const { ethers } = require("hardhat");

async function main() {
  // Get the contract factory
  const FiatsendNFT = await ethers.deployContract("FiatsendNFT");

  await FiatsendNFT.waitForDeployment();
  console.log("fiatsend contract deployed to:", FiatsendNFT.target);
}

// Execute the main function
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
