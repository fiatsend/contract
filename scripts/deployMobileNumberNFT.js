const { ethers, upgrades } = require("hardhat");

async function main() {
  const MobileNumberNFT = await ethers.getContractFactory("MobileNumberNFT");

  // ✅ Deploy as an upgradeable contract
  const proxy = await upgrades.deployProxy(MobileNumberNFT, [], {
    initializer: "initialize",
  });

  await proxy.waitForDeployment();

  console.log("MobileNumberNFT Proxy deployed at:", await proxy.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
