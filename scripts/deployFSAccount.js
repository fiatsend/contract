const { ethers } = require("hardhat");

async function main() {
  const bank = await ethers.deployContract("FiatsendAccount", [
    0xe3408eb0d50ebc8dd95e5add37f44acf716205e9,
  ]);
  await bank.waitForDeployment();
  console.log("Bank deployed to:", bank.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
