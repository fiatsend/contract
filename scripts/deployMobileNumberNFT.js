const { ethers, upgrades } = require("hardhat");

async function main() {
  const MobileNumberNFT = await ethers.getContractFactory("MobileNumberNFT");

  const existingProxyAddress = "0x063EC4E9d7C55A572d3f24d600e1970df75e84cA";

  // ✅ Upgrade
  const proxy = await upgrades.upgradeProxy(existingProxyAddress, MobileNumberNFT);

  await proxy.waitForDeployment();

  console.log("MobileNumberNFT Proxy deployed at:", await proxy.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
