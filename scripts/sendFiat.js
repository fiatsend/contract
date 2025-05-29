const { ethers } = require("ethers");

// USDT ABI - only including functions we need
const USDT_ABI = [
  "function transfer(address to, uint256 value) external returns (bool)",
  "function balanceOf(address account) view returns (uint256)",
  "function decimals() view returns (uint8)",
];

async function sendFiat(amount) {
  try {
    // Check if MetaMask is installed
    if (!window.ethereum) {
      throw new Error("Please install MetaMask");
    }

    // Request account access
    const accounts = await window.ethereum.request({
      method: "eth_requestAccounts",
    });

    // Switch to Sepolia network
    await window.ethereum.request({
      method: "wallet_switchEthereumChain",
      params: [{ chainId: "0x106A" }], // Chain ID for Lisk Sepolia
    });

    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner();

    // USDT contract instance
    const usdtContract = new ethers.Contract(
      "0xAE134a846a92CA8E7803Ca075A1a0EE854Cd6168", // USDT contract address
      USDT_ABI,
      signer
    );

    // Get USDT decimals
    const decimals = await usdtContract.decimals();

    // Convert amount to proper decimal places
    const amountInWei = ethers.parseUnits(amount.toString(), decimals);

    // Send USDT
    const tx = await usdtContract.transfer(
      "0x1731D34B07CA2235E668c7B0941d4BfAB370a2d0", // Recipient address
      amountInWei
    );

    // Wait for transaction to be mined
    const receipt = await tx.wait();

    return {
      success: true,
      hash: receipt.hash,
    };
  } catch (error) {
    console.error("Error:", error);
    return {
      success: false,
      error: error.message,
    };
  }
}

// Example usage in your frontend:
async function handleSendFiat(amount) {
  const result = await sendFiat(amount);
  if (result.success) {
    console.log("Transaction successful! Hash:", result.hash);
  } else {
    console.error("Transaction failed:", result.error);
  }
}
