// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

struct StrategyInfo {
    address underlying;
    address bridge;
}

struct BridgeInteractionInfo {
    address bridge;
    uint256 amount;
}

struct StrategyReportL2 {
    address l1Strategy;
    uint256 actionId;
    uint256 amount;
}

struct StrategyReportL1 {
    address l1Strategy;
    uint256 l1Nav;
    uint256 amount;
}

interface IPoolingManager {
    // Events
    event PendingRequestsExecuted(uint256[] indices);
    event MessageResentToL2();
    event BridgeCancelDepositRequestClaimedAndDeposited(address l1BridgeAddress, uint256 amount, uint256 nonce);
    event CancelDepositRequestBridgeSent(address l1BridgeAddress, uint256 amount, uint256 nonce);
    event ReportHandled(uint256 epoch, StrategyReportL1[] strategyReportL1);
    event StrategyRegistered(address strategy, StrategyInfo strategyInfo);

    // Functions
    function initialize(address _owner, uint256 _l2PoolingManager, address _starknetCore, address _relayer) external;

    function hashFromCalldata(
        BridgeInteractionInfo[] calldata bridgeWithdrawInfo,
        StrategyReportL2[] calldata strategyReportL2,
        BridgeInteractionInfo[] calldata bridgeDepositInfo
    ) external pure returns (uint256);

    function hashFromReportL1(
        uint256 epoch,
        StrategyReportL1[] calldata strategyReportL1
    ) external pure returns (uint256);

    function bridgeEthFeesMultiplicator(
        BridgeInteractionInfo[] calldata bridgeDepositInfo
    ) external view returns (uint256);

    function registerStrategy(address _strategy, address _underlying, address _bridge) external payable;

    function resendMessageToL2() external payable returns (uint256);

    function cancelDepositRequestBridge(
        address l1BridgeAddress,
        uint256 amount,
        uint256 nonce
    ) external returns (uint256);

    function claimBridgeCancelDepositRequestAndDeposit(
        address l1BridgeAddress,
        uint256 amount,
        uint256 nonce,
        uint256 l2BridgeEthFee
    ) external payable;

    function executePendingRequests() external;

    function handleReport(
        BridgeInteractionInfo[] calldata bridgeWithdrawInfo,
        StrategyReportL2[] calldata strategyReportL2,
        BridgeInteractionInfo[] calldata bridgeDepositInfo,
        uint256 l2BridgeEthFee,
        uint256 l2MessagingEthFee
    ) external payable;
}
