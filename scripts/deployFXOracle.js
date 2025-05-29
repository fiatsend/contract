//const { ethers } = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying FxOracle with the account:", deployer.address);

  const staleTimeout = 3600; // 1 hour in seconds
  const fxOracle = await ethers.deployContract("FxOracle", [staleTimeout, deployer.address]);

  await fxOracle.waitForDeployment();
  console.log("FxOracle deployed to:", await fxOracle.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
