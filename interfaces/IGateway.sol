// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

interface IGateway {
    struct Order {
        address sender;
        address token;
        uint256 amount;
        uint256 protocolFee;
        address senderFeeRecipient;
        uint256 senderFee;
        address refundAddress;
        bool isFulfilled;
        bool isRefunded;
        uint64 currentBPS;
        string localCurrency;
        string paymentChannel;
    }

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
    ) external returns (bytes32 orderId);

    function settle(
        bytes32 _splitOrderId,
        bytes32 _orderId,
        address _liquidityProvider,
        uint64 _settlePercent
    ) external returns (bool);

    function refund(uint256 _fee, bytes32 _orderId) external returns (bool);

    function getOrderInfo(bytes32 _orderId) external view returns (Order memory);

    function isTokenSupported(address _token) external view returns (bool);

    function getFeeDetails() external view returns (uint64 protocolFeePercent, uint64 maxBps);
}
