// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

contract TokenFaucet is Initializable, UUPSUpgradeable, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    IERC20 public tether;
    IERC20 public fsend;
    IERC20 public ghsfiat;

    uint256 public constant REQUEST_AMOUNT = 100 * 10**18;
    uint256 public constant ETH_REQUEST_AMOUNT = 0.001 ether;
    uint256 public constant COOLDOWN_TIME = 24 hours;

    mapping(address => uint256) public lastRequestTime;
    mapping(address => bool) public trustedRelayers;

    event TokensRequested(address indexed user, address indexed relayer);
    event TokensDistributed(address indexed user, uint256 ethAmount, uint256 tokenAmount);
    event RelayerUpdated(address indexed relayer, bool status);

    function initialize(address _tether, address _fsend, address _ghsfiat) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        tether = IERC20(_tether);
        fsend = IERC20(_fsend);
        ghsfiat = IERC20(_ghsfiat);
    }

    modifier onlyRelayer() {
        require(trustedRelayers[msg.sender], "Not an authorized relayer");
        _;
    }

    function requestTokens() public nonReentrant {
        _executeRequest(msg.sender);
    }

    function requestTokensViaRelayer(address user) public onlyRelayer nonReentrant {
        _executeRequest(user);
        emit TokensRequested(user, msg.sender);
    }

    function _executeRequest(address user) internal {
        require(block.timestamp >= lastRequestTime[user] + COOLDOWN_TIME, "Cooldown period not met");

        // Update state first to prevent reentrancy
        lastRequestTime[user] = block.timestamp;

        // Distribute tokens using SafeERC20
        _requestToken(user, tether);
        _requestToken(user, fsend);
        _requestToken(user, ghsfiat);

        // Distribute ETH if available
        uint256 ethDistributed = 0;
        if (address(this).balance >= ETH_REQUEST_AMOUNT) {
            (bool sent, ) = payable(user).call{value: ETH_REQUEST_AMOUNT}("");
            if (sent) {
                ethDistributed = ETH_REQUEST_AMOUNT;
            } // Silently skip if transfer fails (e.g., due to gas)
        }

        emit TokensDistributed(user, ethDistributed, REQUEST_AMOUNT);
    }

    function _requestToken(address user, IERC20 token) internal {
        require(token.balanceOf(address(this)) >= REQUEST_AMOUNT, "Insufficient tokens in faucet");
        token.safeTransfer(user, REQUEST_AMOUNT); // Using SafeERC20
    }

    function updateRelayer(address relayer, bool status) external onlyOwner {
        trustedRelayers[relayer] = status;
        emit RelayerUpdated(relayer, status);
    }

    receive() external payable {}

    function withdrawETH(uint256 amount) external onlyOwner {
        require(address(this).balance >= amount, "Insufficient ETH balance");
        (bool sent, ) = payable(owner()).call{value: amount}("");
        require(sent, "ETH withdrawal failed");
    }

    function withdrawTokens(IERC20 token, uint256 amount) external onlyOwner {
        require(token.balanceOf(address(this)) >= amount, "Insufficient token balance");
        token.safeTransfer(owner(), amount); // Using SafeERC20
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}