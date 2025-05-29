const { ethers, upgrades } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  // Deploy the implementation contract
  const FiatSend = await ethers.getContractFactory("FiatSend");
  
  // Deploy the proxy contract
  const stablecoinAddress = "0xAE134a846a92CA8E7803Ca075A1a0EE854Cd6168"; // Replace with actual stablecoin address
  const conversionRate = 1011; // 1:1 conversion rate
  const ghsFiatToken = "0x84Fd74850911d28C4B8A722b6CE8Aa0Df802f08A"; // Replace with actual GHSFIAT token address
  const kycAdmin = deployer.address; // Initially set deployer as KYC admin

  const fiatSend = await upgrades.deployProxy(FiatSend, [
    stablecoinAddress,
    conversionRate,
    ghsFiatToken,
    kycAdmin
  ], {
    initializer: "initialize",
  });

  await fiatSend.waitForDeployment();

  console.log("FiatSend Proxy deployed to:", await fiatSend.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
