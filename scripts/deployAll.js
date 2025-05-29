const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  // Deploy USDT
  const Tether = await ethers.getContractFactory("TetherToken");
  const tether = await Tether.deploy();
  await tether.waitForDeployment();
  console.log("USDT deployed to:", await tether.getAddress());

  // Deploy GHSFIAT
  const GHSFIAT = await ethers.getContractFactory("GHSFIAT");
  const ghsfiat = await GHSFIAT.deploy();
  await ghsfiat.waitForDeployment();
  console.log("GHSFIAT deployed to:", await ghsfiat.getAddress());

  // Deploy Fiatsend with USDT address and initial conversion rate
  const FiatSend = await ethers.getContractFactory("FiatSend");
  const conversionRate = 12; // Example: 1 USDT = 12 GHS
  const fiatsend = await FiatSend.deploy(
    await tether.getAddress(),
    conversionRate,
    await ghsfiat.getAddress()
  );
  await fiatsend.waitForDeployment();
  console.log("Fiatsend deployed to:", await fiatsend.getAddress());

  // Mint initial tokens
  const initialSupply = ethers.parseUnits("1000000", 6); // For USDT
  await tether.mint(deployer.address, initialSupply);

  const ghsfiatSupply = ethers.parseUnits("1000000", 18); // For GHSFIAT
  await ghsfiat.mint(await fiatsend.getAddress(), ghsfiatSupply);

  // Approve Fiatsend contract to spend USDT
  await tether.approve(await fiatsend.getAddress(), initialSupply);
  console.log("Approved Fiatsend to spend USDT");

  // Verify deployer address in Fiatsend
  await fiatsend.verifyUser(deployer.address);
  console.log("Verified deployer address in Fiatsend");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
