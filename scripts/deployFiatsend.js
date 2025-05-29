const { ethers } = require("hardhat");

async function main() {
  const stablecoinAddress = "0x15b2d57d0D447A2DaC6b31d70e1C72F99A0cdb39";
  const ghsFiatAddress = "0x70a5057608A8c517Dc73db4f20c31A969B9C02A4";
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
