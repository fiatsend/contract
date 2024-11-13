const { ethers } = require("hardhat");

async function main() {
  const bank = await ethers.deployContract("FiatsendAccount");
  await bank.waitForDeployment();
  console.log("Bank deployed to:", bank.target);

  const exchange = await ethers.deployContract("Exchange");
  await exchange.waitForDeployment();
  console.log("Exchange deployed to:", exchange.target);

  const kyc = await ethers.deployContract("KYC");
  await kyc.waitForDeployment();
  console.log("KYC deployed to:", kyc.target);

  const oracle = await ethers.deployContract("Oracle");
  await oracle.waitForDeployment();
  console.log("Oracle deployed to:", oracle.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
