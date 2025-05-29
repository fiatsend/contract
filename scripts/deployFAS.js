const { ethers, upgrades } = require("hardhat");

async function main() {
  const FAS = await ethers.deployContract("FiatsendAccountService");
  await FAS.waitForDeployment();
  console.log("FAS deployed to:", FAS.target);

  // Deploy the upgradeable proxy contract
  const fiatsend = await upgrades.deployProxy(FAS, [], {
    initializer: "initialize",
  });

  await fiatsend.waitForDeployment();

  console.log("FiatsendNameService deployed to:", await fiatsend.target());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
