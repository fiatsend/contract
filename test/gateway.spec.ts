import { expect } from "chai";
const { ethers, upgrades } = require("hardhat");

describe("FiatsendGateway", function () {
  let gateway: any;
  let owner: any;
  let user: any;
  let token: any;

  beforeEach(async function () {
    [owner, user] = await ethers.getSigners();

    // Deploy mock stablecoin
    const MockToken = await ethers.getContractFactory("MockERC20");
    token = await MockToken.deploy("MockUSDC", "USDC");
    await token.deployed();

    // Deploy Gateway
    const Gateway = await ethers.getContractFactory("FiatsendGateway");
    gateway = await upgrades.deployProxy(Gateway, [500, owner.address], {
      initializer: "initialize",
    });
    await gateway.deployed();

    // Add aggregator
    await gateway.addAggregator(owner.address);

    // Whitelist token
    await gateway.supportToken(token.address);
  });

  it("should create an order", async function () {
    // Mint & approve tokens
    await token.mint(user.address, ethers.utils.parseUnits("1000", 6));
    await token.connect(user).approve(gateway.address, ethers.utils.parseUnits("1000", 6));

    // Create order
    const tx = await gateway.connect(user).createOrder(
      token.address,
      ethers.utils.parseUnits("100", 6),
      15000, // Example FX rate
      owner.address,
      ethers.utils.parseUnits("1", 6),
      user.address,
      "GHS",
      "MobileMoney",
      "someMessageHash"
    );

    const receipt = await tx.wait();
    expect(receipt.events.find((e: any) => e.event === "OrderCreated")).to.exist;
  });

  // Add tests for settle, refund, pause/unpause, reentrancy, etc.
});
