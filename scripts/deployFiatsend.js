const { ethers } = require("hardhat");

async function main() {
  const stablecoinAddress = "0xAE134a846a92CA8E7803Ca075A1a0EE854Cd6168";
  const ghsFiatAddress = "0x84fd74850911d28c4b8a722b6ce8aa0df802f08a";
  const conversionRate = 1530;

  const fiatsend = await ethers.deployContract("FiatSend", [
    stablecoinAddress,
    conversionRate,
    ghsFiatAddress,
  ]);
  await fiatsend.waitForDeployment();
  console.log("fiatsend contract deployed to:", fiatsend.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
