const { ethers } = require("hardhat");

async function main() {
  const tetherToken = "0xAE134a846a92CA8E7803Ca075A1a0EE854Cd6168";
  const fsToken = "0x47e71D5B59A0c8cA50a7d5e268434aA0F7E171A2";
  const ghsFiatToken = "0x84Fd74850911d28C4B8A722b6CE8Aa0Df802f08A";

  const TokenFaucet = await ethers.getContractFactory("TokenFaucet");

  // Deploy the upgradeable proxy
  const faucet = await upgrades.deployProxy(
    TokenFaucet,
    [tetherToken, fsToken, ghsFiatToken],
    {
      initializer: "initialize",
    }
  );
  await faucet.waitForDeployment();
  console.log("fiatsend contract deployed to:", faucet.target);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
