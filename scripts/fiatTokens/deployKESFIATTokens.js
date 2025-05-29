const { ethers } = require("hardhat");

async function main() {
  const address = "0xddb68f1c22310084390853d5eb21313a78066480";

  const fiatKES = await ethers.deployContract("KESFIAT", [address]);
  await fiatKES.waitForDeployment();
  console.log("fiatsend contract deployed to:", fiatKES.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
