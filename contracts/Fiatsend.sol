// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

// Custom errors
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

contract FiatSend is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    address public stablecoinAddress;
    uint256 public conversionRate;
    ERC20Upgradeable public ghsFiatToken;
    address public kycAdmin;

    // State variables
    mapping(address => uint8) public kycLevel;
    mapping(address => uint256) public monthlySpent;
    mapping(address => uint256) public totalOffRampAmount;

    uint256 constant LEVEL_1_LIMIT = 10_000e18; //monthly limit should be variable
    uint256 constant LEVEL_2_LIMIT = 500_000e18;
    uint256 constant UNVERIFIED_LIMIT = 1_00e18;

    // Events
    event StablecoinReceived(address indexed user, uint256 amount, uint256 ghsAmount);
    event KYCVerified(address indexed user, uint8 level);
    event FiatSent(address indexed user, uint256 usdtAmount, uint256 fiatAmount);
    event ConversionRateUpdated(uint256 newRate);
    event KYCAdminUpdated(address newKycAdmin);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _stablecoinAddress,
        uint256 _conversionRate,
        address _ghsFiatToken,
        address _kycAdmin
    ) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        if (_stablecoinAddress == address(0) || _ghsFiatToken == address(0) || _kycAdmin == address(0)) {
            revert ZeroAddressNotAllowed();
        }

        stablecoinAddress = _stablecoinAddress;
        conversionRate = _conversionRate;
        ghsFiatToken = ERC20Upgradeable(_ghsFiatToken);
        kycAdmin = _kycAdmin;
    }

    modifier onlyKYCAdmin() {
        if (msg.sender != kycAdmin) revert NotKYCAdmin();
        _;
    }

    function updateKYCStatus(address user, uint8 level) external onlyKYCAdmin {
        if (user == address(0)) revert ZeroAddressNotAllowed();
        if (level > 2) revert InvalidKYCLevel();
        kycLevel[user] = level;
        emit KYCVerified(user, level);
    }

    function offRamp(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();

        address sender = msg.sender;
        uint8 level = kycLevel[sender];
        uint256 limit = _getTransactionLimit(level);

        uint256 spent = level == 0 ? totalOffRampAmount[sender] : monthlySpent[sender];
        if (spent + amount > limit) revert ExceedsTransactionLimit();

        ERC20Upgradeable stablecoin = ERC20Upgradeable(stablecoinAddress);
        ERC20Upgradeable ghsToken = ghsFiatToken;

        if (stablecoin.allowance(sender, address(this)) < amount) revert InsufficientAllowance();
        if (stablecoin.balanceOf(sender) < amount) revert InsufficientBalance();
        if (!stablecoin.transferFrom(sender, address(this), amount)) revert TransferFailed();

        uint256 ghsFiatAmount = (amount * conversionRate) / 100;
        if (ghsToken.balanceOf(address(this)) < ghsFiatAmount) revert InsufficientGHSFIATBalance();
        if (!ghsToken.transfer(sender, ghsFiatAmount)) revert GHSFIATTransferFailed();

        if (level == 0) {
            totalOffRampAmount[sender] += amount;
        } else {
            monthlySpent[sender] += amount;
        }

        emit StablecoinReceived(sender, amount, ghsFiatAmount);
    }

    function _getTransactionLimit(uint8 level) internal pure returns (uint256) {
        if (level == 1) return LEVEL_1_LIMIT;
        if (level == 2) return LEVEL_2_LIMIT;
        return UNVERIFIED_LIMIT;
    }

    function setKYCAdmin(address _kycAdmin) external onlyOwner {
        if (_kycAdmin == address(0)) revert ZeroAddressNotAllowed();
        kycAdmin = _kycAdmin;
        emit KYCAdminUpdated(_kycAdmin);
    }

    function updateConversionRate(uint256 newRate) external onlyOwner {
        conversionRate = newRate;
        emit ConversionRateUpdated(newRate);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    receive() external payable {
        revert("ETH not supported");
    }

    fallback() external payable {
        revert("Function not found");
    }
}
