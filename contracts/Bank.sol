// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Fiatsend is Ownable {
    // Events
    event KYCVerified(address indexed user, uint8 level);
    event StablecoinDeposited(address indexed user, address token, uint256 amount);
    event AllowanceSet(address indexed user, uint256 allowance);
    event FiatWithdrawalProcessed(address indexed user, uint256 amount);

    // State Variables
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint8) public kycLevel;
    mapping(address => uint256) public allowance;
    mapping(address => uint256) public monthlySpent;

    uint256 constant LEVEL_1_LIMIT = 100000 * 10**18; // 100,000 GHSFIAT per month
    uint256 constant LEVEL_2_LIMIT = 500000 * 10**18; // 500,000 GHSFIAT per month
    uint256 constant UNVERIFIED_LIMIT = 1000 * 10**18; // 1,000 GHSFIAT one-time limit

    IERC20 public usdcToken;
    IERC20 public usdtToken;
    ERC20Burnable public ghsFiatToken;

    // Administrative Roles
    address public kycAdmin;

    // Modifiers
    modifier onlyKYCAdmin() {
        require(msg.sender == kycAdmin, "Caller is not the KYC Admin");
        _;
    }

    modifier isVerified(address user) {
        require(isWhitelisted[user], "User is not KYC verified");
        _;
    }

    constructor(address _usdc, address _usdt, address _ghsFiat) Ownable(msg.sender) {
    usdcToken = IERC20(_usdc);
    usdtToken = IERC20(_usdt);
    ghsFiatToken = ERC20Burnable(_ghsFiat);
}

    // KYC Functions
    function updateKYCStatus(address user, uint8 level) external onlyKYCAdmin {
        require(level <= 2, "Invalid KYC level");
        kycLevel[user] = level;
        isWhitelisted[user] = (level > 0);
        emit KYCVerified(user, level);
    }

    function getKYCLevel(address user) external view returns (uint8) {
        return kycLevel[user];
    }

    // Stablecoin Deposit
    function depositStablecoin(address token, uint256 amount) external isVerified(msg.sender) {
        require(token == address(usdcToken) || token == address(usdtToken), "Unsupported stablecoin");
        require(amount > 0, "Amount must be greater than zero");

        uint8 level = kycLevel[msg.sender];
        uint256 limit = _getTransactionLimit(level);
        require(monthlySpent[msg.sender] + amount <= limit, "Exceeds transaction limit");

        // Transfer stablecoins from user to the contract
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // Issue GHSFIAT tokens
        ghsFiatToken.transfer(msg.sender, amount);

        monthlySpent[msg.sender] += amount;
        emit StablecoinDeposited(msg.sender, token, amount);
    }

    // Set Spending Allowance
    function setSpendingAllowance(uint256 amount) external isVerified(msg.sender) {
        uint8 level = kycLevel[msg.sender];
        uint256 limit = _getTransactionLimit(level);
        require(amount <= limit, "Allowance exceeds transaction limit");

        allowance[msg.sender] = amount;
        emit AllowanceSet(msg.sender, amount);
    }

    // Fiat Withdrawal
    function processFiatWithdrawal(uint256 amount) external isVerified(msg.sender) {
        uint8 level = kycLevel[msg.sender];
        uint256 limit = _getTransactionLimit(level);
        require(monthlySpent[msg.sender] + amount <= limit, "Exceeds transaction limit");

        // Burn GHSFIAT tokens from user
        ghsFiatToken.burnFrom(msg.sender, amount);

        // Handle fiat transfer via external system (backend integration)
        monthlySpent[msg.sender] += amount;
        emit FiatWithdrawalProcessed(msg.sender, amount);
    }

    // Administrative Functions
    function setKYCAdmin(address admin) external onlyOwner {
        kycAdmin = admin;
    }

    function setStablecoinAddresses(address usdc, address usdt) external onlyOwner {
        usdcToken = IERC20(usdc);
        usdtToken = IERC20(usdt);
    }

    function setGHSFiatToken(address ghsFiat) external onlyOwner {
        ghsFiatToken = ERC20Burnable(ghsFiat);
    }

    // Helper Functions
    function _getTransactionLimit(uint8 level) internal pure returns (uint256) {
        if (level == 1) return LEVEL_1_LIMIT;
        if (level == 2) return LEVEL_2_LIMIT;
        return UNVERIFIED_LIMIT;
    }
}
