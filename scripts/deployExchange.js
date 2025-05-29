const { ethers } = require("hardhat");

async function main() {
  const exchange = await ethers.deployContract(
    "Exchange",
    [
      0xe3408eb0d50ebc8dd95e5add37f44acf716205e9,
      0x40a0eb53fd5c5f5aeccb4b2eb80c7745446c5f15,
    ]
  );
  await exchange.waitForDeployment();
  console.log("Exchange deployed to:", exchange.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
