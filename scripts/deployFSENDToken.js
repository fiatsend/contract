const { ethers } = require("hardhat");

async function main() {
  const address = "0xddb68f1c22310084390853d5eb21313a78066480";

  const fstoken = await ethers.deployContract("FiatsendToken", [address]);
  await fstoken.waitForDeployment();
  console.log("fiatsend contract deployed to:", fstoken.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });