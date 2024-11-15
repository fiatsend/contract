const { ethers } = require("hardhat");

async function main() {
  const stablecoinAddress = "0xddb68f1c22310084390853d5eb21313a78066480";
  const conversionRate = 17;

  const fiatsend = await ethers.deployContract("FiatSend", [
    stablecoinAddress,
    conversionRate,
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
