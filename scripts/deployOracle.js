//const { ethers } = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
  //const INITIAL_EXCHANGE_RATE = ethers.utils.parseUnits("17", "ether");
  const oracle = await ethers.deployContract("Oracle", [17]);
  await oracle.waitForDeployment();
  console.log("Oracle deployed to:", oracle.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
