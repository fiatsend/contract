const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with:", deployer.address);

  const FiatsendGateway = await ethers.getContractFactory("FiatsendGateway");
  const protocolFeePercent = 500; // 0.5% in BPS terms (500 / 100,000)
  const treasuryAddress = deployer.address; // Replace with multisig or DAO

  const proxy = await upgrades.deployProxy(
    FiatsendGateway,
    [protocolFeePercent, treasuryAddress],
    { initializer: "initialize" }
  );

  await proxy.deployed();

  console.log("FiatsendGateway deployed to:", proxy.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
