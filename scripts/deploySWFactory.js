const { ethers } = require("hardhat");

async function main() {
  const smartWalletAddress = "0x2EBB77e0950bf2Ab184e82440c2EEc25026d30Bd";

  const SmartWalletFactory = await ethers.getContractFactory(
    "SmartWalletFactory"
  );
  const factory = await SmartWalletFactory.deploy(smartWalletAddress);
  await factory.waitForDeployment();

  console.log("SmartWalletFactory deployed at:", await factory.target());
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
