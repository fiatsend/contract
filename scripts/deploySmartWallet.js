const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Deploying contracts with account: ${deployer.address}`);

  const SmartWallet = await ethers.getContractFactory("SmartWallet");

  // Deploy Proxy Contract
  const gelatoForwarder = "0xd8253782c45a12053594b9deB72d8e8aB2Fca54c";
  const smartWalletProxy = await upgrades.deployProxy(
    SmartWallet,
    [deployer.address, gelatoForwarder],
    {
      initializer: "initialize",
    }
  );

  await smartWalletProxy.waitForDeployment();
  console.log(
    `SmartWallet Proxy deployed at: ${await smartWalletProxy.getAddress()}`
  );
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
