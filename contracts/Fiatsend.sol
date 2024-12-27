// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract FiatSend {
    // State Variables
    address public admin;
    address public stablecoinAddress;
    uint256 public conversionRate;
    IERC20 public ghsFiatToken;
    address public kycAdmin;

    // KYC and Limits
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint8) public kycLevel;
    mapping(address => uint256) public monthlySpent;
    mapping(address => uint256) public totalOffRampAmount;

    uint256 constant LEVEL_1_LIMIT = 100000 * 10**18; // 100,000 USDT per month
    uint256 constant LEVEL_2_LIMIT = 500000 * 10**18; // 500,000 USDT per month
    uint256 constant UNVERIFIED_LIMIT = 1000 * 10**18; // 1,000 USDT one-time limit

    // Events
    event StablecoinReceived(address indexed user, uint256 amount, uint256 ghsAmount);
    event KYCVerified(address indexed user, uint8 level);
    event FiatSent(address indexed user, uint256 usdtAmount, uint256 fiatAmount);

    // Modifiers
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    modifier onlyKYCAdmin() {
        require(msg.sender == kycAdmin, "Caller is not the KYC Admin");
        _;
    }

    constructor(address _stablecoinAddress, uint256 _conversionRate, address _ghsFiatToken) {
        admin = msg.sender;
        kycAdmin = msg.sender;
        stablecoinAddress = _stablecoinAddress;
        conversionRate = _conversionRate;
        ghsFiatToken = IERC20(_ghsFiatToken);
    }

    // KYC Functions
    function updateKYCStatus(address user, uint8 level) external onlyKYCAdmin {
        require(level <= 2, "Invalid KYC level");
        kycLevel[user] = level;
        isWhitelisted[user] = (level > 0);
        emit KYCVerified(user, level);
    }

    // Core function with KYC and limit checks
    function offRamp(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");

        uint8 level = kycLevel[msg.sender];
        uint256 limit = _getTransactionLimit(level);

        if (level == 0) {
            // Unverified user: enforce one-time limit
            require(totalOffRampAmount[msg.sender] + amount <= limit, "Exceeds one-time limit for unverified user");
        } else {
            // Verified user: enforce monthly limit
            require(monthlySpent[msg.sender] + amount <= limit, "Exceeds monthly limit");
        }

        IERC20 stablecoin = IERC20(stablecoinAddress);
        require(stablecoin.allowance(msg.sender, address(this)) >= amount, "Insufficient allowance");
        require(stablecoin.balanceOf(msg.sender) >= amount, "Insufficient balance");

        require(stablecoin.transferFrom(msg.sender, address(this), amount), "Transfer failed");

        uint256 ghsFiatAmount = (amount * conversionRate) / 100;
        require(ghsFiatToken.balanceOf(address(this)) >= ghsFiatAmount, "Insufficient GHSFIAT");
        require(ghsFiatToken.transfer(msg.sender, ghsFiatAmount), "GHSFIAT transfer failed");

        if (level == 0) {
            totalOffRampAmount[msg.sender] += amount;
        } else {
            monthlySpent[msg.sender] += amount;
        }

        emit StablecoinReceived(msg.sender, amount, ghsFiatAmount);
    }

    // Helper function for limits
    function _getTransactionLimit(uint8 level) internal pure returns (uint256) {
        if (level == 1) return LEVEL_1_LIMIT;
        if (level == 2) return LEVEL_2_LIMIT;
        return UNVERIFIED_LIMIT;
    }

    // Admin functions
    function setKYCAdmin(address _kycAdmin) external onlyAdmin {
        kycAdmin = _kycAdmin;
    }

    function updateConversionRate(uint256 newRate) external onlyAdmin {
        conversionRate = newRate;
    }

    // Prevent ETH transfers
    receive() external payable {
        revert("ETH not supported");
    }

    fallback() external payable {
        revert("Function not found");
    }
}
