const { ethers } = require("hardhat");

async function main() {
  const kyc = await ethers.deployContract("KYC");
  await kyc.waitForDeployment();
  console.log("KYC deployed to:", kyc.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
