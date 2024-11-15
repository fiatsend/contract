// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract FiatSend {
    address public admin; // Address of the Fiatsend admin
    address public stablecoinAddress; // Address of the stablecoin contract (e.g., USDC or USDT)
    uint256 public conversionRate; // Conversion rate from USD to GHS (e.g., 1 USDC = 17 GHS)

    // Events
    event StablecoinReceived(address indexed user, uint256 amount, uint256 ghsAmount);

    // Mapping to track registered users' wallet and bank account verification
    mapping(address => bool) public isVerifiedUser;

    constructor(address _stablecoinAddress, uint256 _conversionRate) {
        admin = msg.sender;
        stablecoinAddress = _stablecoinAddress;
        conversionRate = _conversionRate;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    // Function to register or verify a user's wallet address
    function verifyUser(address user) external onlyAdmin {
        isVerifiedUser[user] = true;
    }

    // Function to update the conversion rate (e.g., in case of currency fluctuation)
    function updateConversionRate(uint256 newRate) external onlyAdmin {
        conversionRate = newRate;
    }

    // Core function to receive stablecoins and trigger GHS disbursement
    function depositStablecoin(uint256 amount) external {
        require(isVerifiedUser[msg.sender], "User is not verified");
        require(amount > 0, "Amount must be greater than zero");

        // Transfer stablecoin from the user to this contract
        IERC20 stablecoin = IERC20(stablecoinAddress);
        require(stablecoin.transferFrom(msg.sender, address(this), amount), "Stablecoin transfer failed");

        // Calculate equivalent GHS amount
        uint256 ghsAmount = amount * conversionRate;

        // Emit event to trigger off-chain disbursement
        emit StablecoinReceived(msg.sender, amount, ghsAmount);
    }

    // Admin function to withdraw stablecoins from the contract
    function withdrawStablecoin(uint256 amount) external onlyAdmin {
        IERC20 stablecoin = IERC20(stablecoinAddress);
        require(stablecoin.transferFrom(address(this), admin, amount), "Withdrawal failed");
    }
}
