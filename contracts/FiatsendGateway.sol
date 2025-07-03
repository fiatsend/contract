// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// ===== OpenZeppelin Upgradeable =====
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// ===== Interfaces & Managers =====
// Create your IGateway and GatewaySettingManager to match this structure
import {IGateway} from "./interfaces/IGateway.sol";
import {GatewaySettingManager} from "./GatewaySettingManager.sol";

contract FiatsendGateway is
    IGateway,
    GatewaySettingManager,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    Ownable2StepUpgradeable
{
    // =============================================
    //              DATA STRUCTURES
    // =============================================
    struct Order {
        address sender;
        address token;
        uint256 amount;           // stablecoin amount
        uint256 protocolFee;
        address senderFeeRecipient;
        uint256 senderFee;
        address refundAddress;
        bool isFulfilled;
        bool isRefunded;
        uint64 currentBPS;
        string localCurrency;     // e.g. GHS, NGN
        string paymentChannel;    // e.g. mobile money, bank transfer
    }

    // =============================================
    //                  STORAGE
    // =============================================
    mapping(bytes32 => Order) private orders;
    mapping(address => uint256) private _nonce;
    mapping(address => bool) private _aggregators;

    uint64 public protocolFeePercent;
    uint64 public MAX_BPS;

    address public treasuryAddress;

    uint256[50] private __gap;

    // =============================================
    //                   EVENTS
    // =============================================
    event OrderCreated(
        address indexed sender,
        bytes32 indexed orderId,
        address token,
        uint256 amount,
        uint256 protocolFee,
        string localCurrency,
        string paymentChannel,
        uint96 rate,
        string messageHash
    );

    event OrderSettled(
        bytes32 indexed splitOrderId,
        bytes32 indexed orderId,
        address indexed liquidityProvider,
        uint256 liquidityProviderAmount,
        uint256 protocolFeeAmount
    );

    event OrderRefunded(bytes32 indexed orderId, uint256 refundAmount);

    event SenderFeeTransferred(address indexed recipient, uint256 amount);

    event AggregatorAdded(address indexed aggregator);
    event AggregatorRemoved(address indexed aggregator);

    // =============================================
    //                INITIALIZER
    // =============================================
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(
        uint64 _protocolFeePercent,
        address _treasuryAddress
    ) external initializer {
        require(_treasuryAddress != address(0), "ZeroTreasuryAddress");

        __Ownable2Step_init();
        __Pausable_init();
        __ReentrancyGuard_init();

        protocolFeePercent = _protocolFeePercent;
        MAX_BPS = 100_000;
        treasuryAddress = _treasuryAddress;
    }

    // =============================================
    //                 MODIFIERS
    // =============================================
    modifier onlyAggregator() {
        require(_aggregators[msg.sender], "OnlyAggregator");
        _;
    }

    // =============================================
    //                OWNER FUNCTIONS
    // =============================================

    function addAggregator(address aggregator) external onlyOwner {
        require(aggregator != address(0), "ZeroAggregator");
        _aggregators[aggregator] = true;
        emit AggregatorAdded(aggregator);
    }

    function removeAggregator(address aggregator) external onlyOwner {
        _aggregators[aggregator] = false;
        emit AggregatorRemoved(aggregator);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function updateProtocolFee(uint64 _newFee) external onlyOwner {
        protocolFeePercent = _newFee;
    }

    function updateTreasury(address _newTreasury) external onlyOwner {
        require(_newTreasury != address(0), "ZeroTreasury");
        treasuryAddress = _newTreasury;
    }

    /// Emergency withdrawal
    function rescueFunds(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }

    // =============================================
    //                USER CALLS
    // =============================================

    function createOrder(
        address _token,
        uint256 _amount,
        uint96 _rate,
        address _senderFeeRecipient,
        uint256 _senderFee,
        address _refundAddress,
        string calldata _localCurrency,
        string calldata _paymentChannel,
        string calldata messageHash
    ) external whenNotPaused nonReentrant returns (bytes32 orderId) {
        _handler(_token, _amount, _refundAddress, _senderFeeRecipient, _senderFee);

        require(bytes(messageHash).length != 0, "InvalidMessageHash");

        IERC20(_token).transferFrom(msg.sender, address(this), _amount + _senderFee);

        _nonce[msg.sender]++;

        orderId = keccak256(abi.encode(msg.sender, _nonce[msg.sender]));

        uint256 _protocolFee = (_amount * protocolFeePercent) / MAX_BPS;

        orders[orderId] = Order({
            sender: msg.sender,
            token: _token,
            amount: _amount,
            protocolFee: _protocolFee,
            senderFeeRecipient: _senderFeeRecipient,
            senderFee: _senderFee,
            refundAddress: _refundAddress,
            isFulfilled: false,
            isRefunded: false,
            currentBPS: MAX_BPS,
            localCurrency: _localCurrency,
            paymentChannel: _paymentChannel
        });

        emit OrderCreated(
            msg.sender,
            orderId,
            _token,
            _amount,
            _protocolFee,
            _localCurrency,
            _paymentChannel,
            _rate,
            messageHash
        );
    }

    // =============================================
    //              AGGREGATOR FUNCTIONS
    // =============================================

    function settle(
        bytes32 _splitOrderId,
        bytes32 _orderId,
        address _liquidityProvider,
        uint64 _settlePercent
    ) external onlyAggregator whenNotPaused nonReentrant returns (bool) {
        Order storage ord = orders[_orderId];
        require(!ord.isFulfilled, "AlreadyFulfilled");
        require(!ord.isRefunded, "AlreadyRefunded");

        ord.currentBPS -= _settlePercent;

        if (ord.currentBPS == 0) {
            ord.isFulfilled = true;

            if (ord.senderFee != 0) {
                IERC20(ord.token).transfer(ord.senderFeeRecipient, ord.senderFee);
                emit SenderFeeTransferred(ord.senderFeeRecipient, ord.senderFee);
            }
        }

        uint256 liquidityProviderAmount = (ord.amount * _settlePercent) / MAX_BPS;
        ord.amount -= liquidityProviderAmount;

        uint256 protocolFeeAmount = (liquidityProviderAmount * protocolFeePercent) / MAX_BPS;
        liquidityProviderAmount -= protocolFeeAmount;

        IERC20(ord.token).transfer(treasuryAddress, protocolFeeAmount);
        IERC20(ord.token).transfer(_liquidityProvider, liquidityProviderAmount);

        emit OrderSettled(
            _splitOrderId,
            _orderId,
            _liquidityProvider,
            liquidityProviderAmount,
            protocolFeeAmount
        );

        return true;
    }

    function refund(uint256 _fee, bytes32 _orderId)
        external
        onlyAggregator
        whenNotPaused
        nonReentrant
        returns (bool)
    {
        Order storage ord = orders[_orderId];
        require(!ord.isFulfilled, "AlreadyFulfilled");
        require(!ord.isRefunded, "AlreadyRefunded");
        require(ord.protocolFee >= _fee, "FeeExceedsProtocolFee");

        if (_fee > 0) {
            IERC20(ord.token).transfer(treasuryAddress, _fee);
        }

        ord.isRefunded = true;
        ord.currentBPS = 0;

        uint256 refundAmount = ord.amount - _fee;

        IERC20(ord.token).transfer(
            ord.refundAddress,
            refundAmount + ord.senderFee
        );

        emit OrderRefunded(_orderId, refundAmount);

        return true;
    }

    // =============================================
    //              INTERNAL UTILS
    // =============================================
    function _handler(
        address _token,
        uint256 _amount,
        address _refundAddress,
        address _senderFeeRecipient,
        uint256 _senderFee
    ) internal view {
        require(_isTokenSupported[_token] == 1, "TokenNotSupported");
        require(_amount != 0, "AmountIsZero");
        require(_refundAddress != address(0), "ZeroRefundAddress");

        if (_senderFee != 0) {
            require(_senderFeeRecipient != address(0), "ZeroSenderFeeRecipient");
        }
    }

    // =============================================
    //                 VIEWS
    // =============================================
    function getOrderInfo(bytes32 _orderId) external view returns (Order memory) {
        return orders[_orderId];
    }

    function isTokenSupported(address _token) external view returns (bool) {
        return _isTokenSupported[_token] == 1;
    }

    function getFeeDetails() external view returns (uint64, uint64) {
        return (protocolFeePercent, MAX_BPS);
    }
}
