// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

// Added new custom errors
error ZeroAddressNotAllowed();
error ReentrancyDetected();
error InsufficientAllowance();
error InsufficientBalance();
error TransferFailed();
error GHSFIATTransferFailed();
error ExceedsTransactionLimit();
error InvalidKYCLevel();
error ZeroAmount();
error NotAdmin();
error NotKYCAdmin();
error InsufficientGHSFIATBalance();

contract FiatSend {
    address public immutable admin;
    address public stablecoinAddress;
    uint256 public conversionRate;
    IERC20 public ghsFiatToken;
    address public kycAdmin;

    // Removed redundant isWhitelisted mapping
    mapping(address => uint8) public kycLevel;
    mapping(address => uint256) public monthlySpent;
    mapping(address => uint256) public totalOffRampAmount;

    uint256 constant LEVEL_1_LIMIT = 100_000e18;
    uint256 constant LEVEL_2_LIMIT = 500_000e18;
    uint256 constant UNVERIFIED_LIMIT = 1_000e18;

    event StablecoinReceived(address indexed user, uint256 amount, uint256 ghsAmount);
    event KYCVerified(address indexed user, uint8 level);
    event FiatSent(address indexed user, uint256 usdtAmount, uint256 fiatAmount);
    event ConversionRateUpdated(uint256 newRate);
    event KYCAdminUpdated(address newKycAdmin);

    modifier onlyAdmin() {
        if (msg.sender != admin) revert NotAdmin();
        _;
    }

    modifier onlyKYCAdmin() {
        if (msg.sender != kycAdmin) revert NotKYCAdmin();
        _;
    }

    constructor(address _stablecoinAddress, uint256 _conversionRate, address _ghsFiatToken) {
        if (_stablecoinAddress == address(0) || _ghsFiatToken == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        admin = msg.sender;
        kycAdmin = msg.sender;
        stablecoinAddress = _stablecoinAddress;
        conversionRate = _conversionRate;
        ghsFiatToken = IERC20(_ghsFiatToken);
    }

    function updateKYCStatus(address user, uint8 level) external onlyKYCAdmin {
        if (user == address(0)) revert ZeroAddressNotAllowed();
        if (level > 2) revert InvalidKYCLevel();
        kycLevel[user] = level;
        emit KYCVerified(user, level);
    }

    bool internal locked;

    modifier nonReentrant() {
        if (locked) revert ReentrancyDetected();
        locked = true;
        _;
        locked = false;
    }

    function offRamp(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        uint8 level = kycLevel[msg.sender];
        uint256 limit = _getTransactionLimit(level);

        if (level == 0) {
            if (totalOffRampAmount[msg.sender] + amount > limit) revert ExceedsTransactionLimit();
        } else {
            if (monthlySpent[msg.sender] + amount > limit) revert ExceedsTransactionLimit();
        }

        IERC20 stablecoin = IERC20(stablecoinAddress);

        if (stablecoin.allowance(msg.sender, address(this)) < amount) revert InsufficientAllowance();
        if (stablecoin.balanceOf(msg.sender) < amount) revert InsufficientBalance();

        if (!stablecoin.transferFrom(msg.sender, address(this), amount)) revert TransferFailed();

        uint256 ghsFiatAmount = (amount * conversionRate) / 100;
        if (ghsFiatToken.balanceOf(address(this)) < ghsFiatAmount) revert InsufficientGHSFIATBalance();
        if (!ghsFiatToken.transfer(msg.sender, ghsFiatAmount)) revert GHSFIATTransferFailed();

        if (level == 0) {
            totalOffRampAmount[msg.sender] += amount;
        } else {
            monthlySpent[msg.sender] += amount;
        }

        emit StablecoinReceived(msg.sender, amount, ghsFiatAmount);
    }

    function _getTransactionLimit(uint8 level) internal pure returns (uint256) {
        if (level == 1) return LEVEL_1_LIMIT;
        if (level == 2) return LEVEL_2_LIMIT;
        return UNVERIFIED_LIMIT;
    }

    function setKYCAdmin(address _kycAdmin) external onlyAdmin {
        if (_kycAdmin == address(0)) revert ZeroAddressNotAllowed();
        kycAdmin = _kycAdmin;
        emit KYCAdminUpdated(_kycAdmin);
    }

    function updateConversionRate(uint256 newRate) external onlyAdmin {
        conversionRate = newRate;
        emit ConversionRateUpdated(newRate);
    }

    receive() external payable {
        revert("ETH not supported");
    }

    fallback() external payable {
        revert("Function not found");
    }
}
