// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {PausableUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {ErrorLib} from "./lib/ErrorLib.sol";
import {Messaging} from "./lib/Messaging.sol";
import "./interfaces/IPoolingManager.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IStrategyBase} from "./interfaces/IStrategyBase.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract PoolingManager is
    UUPSUpgradeable,
    AccessControlUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    Messaging
{
    uint256 public l2PoolingManager;
    mapping(address => StrategyInfo) public strategyInfo;
    uint256 public batchCounter;
    address public ethBridge;
    address public ethWrapped;
    StrategyReportL2[] public pendingRequests;
    StrategyReportL1[] public pendingRequestsExecuted;
    uint256 public pendingRequestsExecutedCounter;

    event PendingRequestsExecuted(uint256[] indices);
    event MessageResentToL2();
    event BridgeCancelDepositRequestClaimedAndDeposited(address l1BridgeAddress, uint256 amount, uint256 nonce);
    event CancelDepositRequestBridgeSent(address l1BridgeAddress, uint256 amount, uint256 nonce);
    event ReportHandled(uint256 epoch, uint256 strategyReportL1Length, StrategyReportL1[] strategyReportL1);
    event StrategyRegistered(address strategy, StrategyInfo strategyInfo);

    uint256 public constant L2_HANDLER_SELECTOR = 0x10e13e50cb99b6b3c8270ec6e16acfccbe1164a629d74b43549567a77593aff;
    bytes32 public constant RELAYER_ROLE = keccak256("0x01");

    /**
     * @dev Receive Ether function
     */
    receive() external payable {}

    /**
     * @dev Fallback function
     */
    fallback() external payable {}

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice Initialier the contract state.
    /// @param _l2PoolingManager troveManager address
    /// @param _starknetCore starknetCore address
    /// @param _relayer relayer address
    function initialize(
        address _owner,
        uint256 _l2PoolingManager,
        address _starknetCore,
        address _relayer,
        address _ethBridge,
        address _ethWrapped
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __UUPSUpgradeable_init();
        initializeMessaging(_starknetCore);
        l2PoolingManager = _l2PoolingManager;
        _grantRole(0, _owner);
        _grantRole(RELAYER_ROLE, _owner);
        _grantRole(RELAYER_ROLE, _relayer);
        ethBridge = _ethBridge;
        ethWrapped = _ethWrapped;
    }

    function hashFromReportL2(
        uint256 epoch,
        BridgeInteractionInfo[] memory bridgeWithdrawInfo,
        StrategyReportL2[] memory strategyReportL2,
        BridgeInteractionInfo[] memory bridgeDepositInfo
    ) public pure returns (uint256) {
        bytes memory encodedData = abi.encodePacked(epoch);

        for (uint i = 0; i < bridgeWithdrawInfo.length; i++) {
            encodedData = abi.encodePacked(
                encodedData,
                uint256(uint160(bridgeWithdrawInfo[i].bridge)),
                bridgeWithdrawInfo[i].amount
            );
        }

        for (uint i = 0; i < strategyReportL2.length; i++) {
            encodedData = abi.encodePacked(
                encodedData,
                uint256(uint160(strategyReportL2[i].l1Strategy)),
                strategyReportL2[i].actionId,
                strategyReportL2[i].amount
            );
        }

        for (uint i = 0; i < bridgeDepositInfo.length; i++) {
            encodedData = abi.encodePacked(
                encodedData,
                uint256(uint160(bridgeDepositInfo[i].bridge)),
                bridgeDepositInfo[i].amount
            );
        }

        uint256 hashValue = uint256(keccak256(encodedData));
        return hashValue;
    }

    function hashFromReportL1(
        uint256 strategyReportL1Length,
        StrategyReportL1[] memory strategyReportL1
    ) public pure returns (uint256) {
        bytes memory encodedData = abi.encodePacked();
        for (uint i = 0; i < strategyReportL1Length; i++) {
            encodedData = abi.encodePacked(
                encodedData,
                uint256(uint160(strategyReportL1[i].l1Strategy)),
                strategyReportL1[i].l1Nav,
                strategyReportL1[i].amount
            );
        }

        uint256 strategyReportL1Hash = uint256(keccak256(encodedData));
        return strategyReportL1Hash;
    }

    function bridgeEthFeesMultiplicator(
        BridgeInteractionInfo[] memory bridgeDepositInfo
    ) public view returns (uint256) {
        uint256 acc = 0;
        for (uint256 index1 = 0; index1 < pendingRequestsExecuted.length; index1++) {
            StrategyReportL1 memory pendingRequestsExecutedElem = pendingRequestsExecuted[index1];
            if (pendingRequestsExecutedElem.amount > 0) {
                bool found = false;
                for (uint256 index2 = 0; index2 < bridgeDepositInfo.length; index2++) {
                    BridgeInteractionInfo memory bridgeDepositInfoElem = bridgeDepositInfo[index2];
                    if (bridgeDepositInfoElem.bridge == strategyInfo[pendingRequestsExecutedElem.l1Strategy].bridge) {
                        found = true;
                    }
                }
                if (!found) {
                    acc++;
                }
            }
        }
        return (bridgeDepositInfo.length + acc);
    }

    function registerStrategy(address _strategy, address _underlying, address _bridge) public payable onlyRole(0) {
        if (_underlying == address(0)) revert ErrorLib.ZeroAddress();
        if (_bridge == address(0)) revert ErrorLib.ZeroAddress();
        if (_strategy == address(0)) revert ErrorLib.ZeroAddress();

        if (IStrategyBase(_strategy).poolingManager() != address(this)) revert ErrorLib.InvalidPoolingManager();

        StrategyInfo memory newStrategyInfo = StrategyInfo({underlying: _underlying, bridge: _bridge});
        strategyInfo[_strategy] = newStrategyInfo;

        IERC20(_underlying).approve(_bridge, type(uint256).max);
        emit StrategyRegistered(_strategy, newStrategyInfo);
    }

    function setPoolingManager(uint256 _l2PoolingManager) public payable onlyRole(0) {
        if (_l2PoolingManager == (0)) revert ErrorLib.ZeroAddress();
        l2PoolingManager = _l2PoolingManager;
    }

    function cancelDepositRequestBridge(address l1BridgeAddress, uint256 amount, uint256 nonce) public onlyRole(0) {
        depositCancelRequestToBridgeToken(l1BridgeAddress, l2PoolingManager, amount, nonce);
        emit CancelDepositRequestBridgeSent(l1BridgeAddress, amount, nonce);
    }

    function claimBridgeCancelDepositRequestAndDeposit(
        address l1BridgeAddress,
        uint256 amount,
        uint256 nonce,
        uint256 l2BridgeEthFee
    ) public payable onlyRole(0) {
        depositReclaimToBridgeToken(l1BridgeAddress, l2PoolingManager, amount, nonce);
        BridgeInteractionInfo[] memory bridgeElemArray = new BridgeInteractionInfo[](1);
        bridgeElemArray[0] = BridgeInteractionInfo({bridge: l1BridgeAddress, amount: amount});
        depositToBridges(bridgeElemArray, l2BridgeEthFee, false);
        emit BridgeCancelDepositRequestClaimedAndDeposited(l1BridgeAddress, amount, nonce);
    }

    function pause() external onlyRole(RELAYER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(0) {
        _unpause();
    }

    function executePendingRequests() public onlyRole(RELAYER_ROLE) {
        uint256[] memory indicesToDelete = new uint256[](pendingRequests.length);
        uint256 indicesToDeleteLength = 0;
        for (uint256 index = 0; index < pendingRequests.length; index++) {
            StrategyReportL2 memory currentReport = pendingRequests[index];
            try
                IStrategyBase(currentReport.l1Strategy).handleReport(currentReport.actionId, currentReport.amount)
            returns (uint256 l1Nav, uint256 amount) {
                indicesToDelete[indicesToDeleteLength] = index;
                indicesToDeleteLength++;
                pendingRequestsExecuted.push(
                    StrategyReportL1({l1Strategy: currentReport.l1Strategy, l1Nav: l1Nav, amount: amount})
                );
            } catch {}
        }

        for (uint256 i = indicesToDeleteLength; i > 0; i--) {
            deleteElement(pendingRequests, indicesToDelete[i - 1]);
        }
        emit PendingRequestsExecuted(indicesToDelete);
    }

    function handleReport(
        uint256 epoch,
        BridgeInteractionInfo[] memory bridgeWithdrawInfo,
        StrategyReportL2[] memory strategyReportL2,
        BridgeInteractionInfo[] memory bridgeDepositInfo,
        uint256 l2BridgeEthFee,
        uint256 l2MessagingEthFee,
        uint256 minSuccessCall
    ) public payable onlyRole(RELAYER_ROLE) whenNotPaused {
        verifyCallData(epoch, bridgeWithdrawInfo, strategyReportL2, bridgeDepositInfo);
        withdrawFromBridges(bridgeWithdrawInfo);
        (
            uint256 strategyReportL1Length,
            StrategyReportL1[] memory strategyReportL1,
            BridgeInteractionInfo[] memory newBridgeDepositInfo
        ) = handleMassReport(strategyReportL2, bridgeDepositInfo);

        if (strategyReportL1Length == 0) revert ErrorLib.NoL1Report();
        if (minSuccessCall > strategyReportL1Length) revert ErrorLib.NotEnoughSuccessCalls();

        depositToBridges(newBridgeDepositInfo, l2BridgeEthFee, true);

        uint256 strategyReportL1Hash = hashFromReportL1(strategyReportL1Length, strategyReportL1);
        uint256[] memory data = getMessagePayloadData(epoch, strategyReportL1Hash);

        _sendMessageToL2(l2PoolingManager, L2_HANDLER_SELECTOR, data, l2MessagingEthFee);

        emit ReportHandled(epoch, strategyReportL1Length, strategyReportL1);
    }

    function getMessagePayloadData(
        uint256 epoch,
        uint256 strategyReportL1Hash
    ) internal pure returns (uint256[] memory) {
        (uint256 lowEpoch, uint256 highEpoch) = u256(epoch);
        (uint256 lowStrategyReportL1Hash, uint256 highStrategyReportL1Hash) = u256(strategyReportL1Hash);

        uint256[] memory data = new uint256[](4);
        data[0] = lowEpoch;
        data[1] = highEpoch;
        data[2] = lowStrategyReportL1Hash;
        data[3] = highStrategyReportL1Hash;
        return (data);
    }

    function deleteElement(StrategyReportL2[] storage array, uint256 index) internal {
        require(index < array.length, "Index out of bounds");
        array[index] = array[array.length - 1];
        array.pop();
    }

    function verifyCallData(
        uint256 epoch,
        BridgeInteractionInfo[] memory bridgeWithdrawInfo,
        StrategyReportL2[] memory strategyReportL2,
        BridgeInteractionInfo[] memory bridgeDepositInfo
    ) internal {
        uint256 hash_from_calldata = hashFromReportL2(epoch, bridgeWithdrawInfo, strategyReportL2, bridgeDepositInfo);
        (uint256 lowHash, uint256 highHash) = u256(hash_from_calldata);
        uint256[] memory data = new uint256[](2);
        data[0] = lowHash;
        data[1] = highHash;
        _consumeL2Message(l2PoolingManager, data);
    }

    function withdrawFromBridges(BridgeInteractionInfo[] memory bridgeWithdrawalInfo) internal {
        for (uint256 index = 0; index < bridgeWithdrawalInfo.length; index++) {
            _withdrawTokenFromBridge(
                bridgeWithdrawalInfo[index].bridge,
                address(this),
                bridgeWithdrawalInfo[index].amount
            );
            if (bridgeWithdrawalInfo[index].bridge == ethBridge) {
                IWETH(ethWrapped).deposit{value: bridgeWithdrawalInfo[index].amount}();
            }
        }
    }

    function depositToBridges(
        BridgeInteractionInfo[] memory bridgeDepositInfo,
        uint256 l2BridgeEthFee,
        bool withdrawEth
    ) internal {
        for (uint256 index = 0; index < bridgeDepositInfo.length; index++) {
            BridgeInteractionInfo memory bridgeInteractionInfoElem = bridgeDepositInfo[index];
            if (bridgeInteractionInfoElem.bridge == ethBridge) {
                if (withdrawEth) {
                    IWETH(ethWrapped).withdraw(bridgeInteractionInfoElem.amount);
                }
                depositToBridgeToken(
                    bridgeInteractionInfoElem.bridge,
                    l2PoolingManager,
                    bridgeInteractionInfoElem.amount,
                    bridgeInteractionInfoElem.amount + l2BridgeEthFee
                );
            } else {
                depositToBridgeToken(
                    bridgeInteractionInfoElem.bridge,
                    l2PoolingManager,
                    bridgeInteractionInfoElem.amount,
                    l2BridgeEthFee
                );
            }
        }
    }

    function handleMassReport(
        StrategyReportL2[] memory strategyReportL2,
        BridgeInteractionInfo[] memory bridgeDepositInfo
    ) internal returns (uint256, StrategyReportL1[] memory, BridgeInteractionInfo[] memory) {
        (
            uint256 strategyReportL1Length,
            StrategyReportL1[] memory strategyReportL1,
            uint256 tempBridgeLossLength,
            BridgeInteractionInfo[] memory tempBridgeLoss
        ) = processStrategyReports(strategyReportL2);

        updateBridgeDepositInfo(tempBridgeLossLength, tempBridgeLoss, bridgeDepositInfo);

        uint256 pendingRequestsExecutedLength = pendingRequestsExecuted.length - pendingRequestsExecutedCounter;

        if (pendingRequestsExecutedLength > 0) {
            return
                processPendingRequests(
                    strategyReportL1Length,
                    strategyReportL1,
                    bridgeDepositInfo,
                    pendingRequestsExecutedLength
                );
        } else {
            return (strategyReportL1Length, strategyReportL1, bridgeDepositInfo);
        }
    }

    function processStrategyReports(
        StrategyReportL2[] memory strategyReportL2
    )
        internal
        returns (
            uint256 strategyReportL1Length,
            StrategyReportL1[] memory strategyReportL1,
            uint256 tempBridgeLossLength,
            BridgeInteractionInfo[] memory tempBridgeLoss
        )
    {
        strategyReportL1 = new StrategyReportL1[](strategyReportL2.length);
        tempBridgeLoss = new BridgeInteractionInfo[](strategyReportL2.length + pendingRequestsExecuted.length);

        for (uint256 i = 0; i < strategyReportL2.length; i++) {
            StrategyReportL2 memory currentReport = strategyReportL2[i];
            StrategyInfo memory currentStrategyInfo = strategyInfo[currentReport.l1Strategy];

            if (currentReport.actionId == 0) {
                IERC20(currentStrategyInfo.underlying).transfer(currentReport.l1Strategy, currentReport.amount);
            }

            try
                IStrategyBase(currentReport.l1Strategy).handleReport(currentReport.actionId, currentReport.amount)
            returns (uint256 l1Nav, uint256 amount) {
                strategyReportL1[strategyReportL1Length] = StrategyReportL1({
                    l1Strategy: currentReport.l1Strategy,
                    l1Nav: l1Nav,
                    amount: amount
                });
                if (currentReport.actionId == 2 && amount != currentReport.amount) {
                    tempBridgeLoss[tempBridgeLossLength] = BridgeInteractionInfo({
                        bridge: currentStrategyInfo.bridge,
                        amount: currentReport.amount - amount
                    });
                    tempBridgeLossLength++;
                }
                strategyReportL1Length++;
            } catch {
                pendingRequests.push(currentReport);
                tempBridgeLoss[tempBridgeLossLength] = BridgeInteractionInfo({
                    bridge: currentStrategyInfo.bridge,
                    amount: currentReport.amount
                });
                tempBridgeLossLength++;
            }
        }

        return (strategyReportL1Length, strategyReportL1, tempBridgeLossLength, tempBridgeLoss);
    }

    function processPendingRequests(
        uint256 strategyReportL1Length,
        StrategyReportL1[] memory strategyReportL1,
        BridgeInteractionInfo[] memory bridgeDepositInfo,
        uint256 pendingRequestsExecutedLength
    ) internal returns (uint256, StrategyReportL1[] memory, BridgeInteractionInfo[] memory) {
        (
            uint256 newStrategyReportL1Length,
            StrategyReportL1[] memory newStrategyReportL1,
            uint256 tempBridgeAdditionalDepositLength,
            BridgeInteractionInfo[] memory tempBridgeAdditionalDeposit
        ) = mergeReportsAndUpdateDeposits(
                strategyReportL1Length,
                strategyReportL1,
                bridgeDepositInfo,
                pendingRequestsExecutedLength
            );

        pendingRequestsExecutedCounter = pendingRequestsExecuted.length;

        if (tempBridgeAdditionalDepositLength > 0) {
            uint256 totalLen = tempBridgeAdditionalDepositLength + bridgeDepositInfo.length;

            BridgeInteractionInfo[] memory newBridgeDepositInfo = new BridgeInteractionInfo[](totalLen);

            for (uint256 i = 0; i < totalLen; i++) {
                if (i < bridgeDepositInfo.length) {
                    newBridgeDepositInfo[i] = bridgeDepositInfo[i];
                } else {
                    newBridgeDepositInfo[i] = tempBridgeAdditionalDeposit[i - bridgeDepositInfo.length];
                }
            }
            return (newStrategyReportL1Length, newStrategyReportL1, newBridgeDepositInfo);
        } else {
            return (newStrategyReportL1Length, newStrategyReportL1, bridgeDepositInfo);
        }
    }

    function mergeReportsAndUpdateDeposits(
        uint256 strategyReportL1Length,
        StrategyReportL1[] memory strategyReportL1,
        BridgeInteractionInfo[] memory bridgeDepositInfo,
        uint256 pendingRequestsExecutedLength
    )
        internal
        view
        returns (
            uint256 newStrategyReportL1Length,
            StrategyReportL1[] memory newStrategyReportL1,
            uint256 tempBridgeAdditionalDepositLength,
            BridgeInteractionInfo[] memory tempBridgeAdditionalDeposit
        )
    {
        newStrategyReportL1Length = strategyReportL1Length + pendingRequestsExecutedLength;
        newStrategyReportL1 = new StrategyReportL1[](newStrategyReportL1Length);
        tempBridgeAdditionalDeposit = new BridgeInteractionInfo[](pendingRequestsExecutedLength);

        for (uint256 i = 0; i < newStrategyReportL1Length; i++) {
            if (i < strategyReportL1Length) {
                newStrategyReportL1[i] = strategyReportL1[i];
            } else {
                tempBridgeAdditionalDepositLength = processPendingRequest(
                    i,
                    strategyReportL1Length,
                    newStrategyReportL1,
                    bridgeDepositInfo,
                    tempBridgeAdditionalDeposit,
                    tempBridgeAdditionalDepositLength
                );
            }
        }

        return (
            newStrategyReportL1Length,
            newStrategyReportL1,
            tempBridgeAdditionalDepositLength,
            tempBridgeAdditionalDeposit
        );
    }

    function processPendingRequest(
        uint256 i,
        uint256 strategyReportL1Length,
        StrategyReportL1[] memory newStrategyReportL1,
        BridgeInteractionInfo[] memory bridgeDepositInfo,
        BridgeInteractionInfo[] memory tempBridgeAdditionalDeposit,
        uint256 tempBridgeAdditionalDepositLength
    ) internal view returns (uint256) {
        uint256 indexCounter = i - strategyReportL1Length;
        StrategyReportL1 memory pendingRequestExecutedElem = pendingRequestsExecuted[indexCounter];
        newStrategyReportL1[i] = pendingRequestExecutedElem;

        if (pendingRequestExecutedElem.amount > 0) {
            StrategyInfo memory currentStrategyInfo = strategyInfo[pendingRequestExecutedElem.l1Strategy];
            bool found = false;
            for (uint256 index = 0; index < bridgeDepositInfo.length; index++) {
                if (bridgeDepositInfo[index].bridge == currentStrategyInfo.bridge) {
                    bridgeDepositInfo[index].amount += pendingRequestExecutedElem.amount;
                    found = true;
                    break;
                }
            }
            if (!found) {
                tempBridgeAdditionalDeposit[tempBridgeAdditionalDepositLength] = BridgeInteractionInfo({
                    bridge: currentStrategyInfo.bridge,
                    amount: pendingRequestExecutedElem.amount
                });
                tempBridgeAdditionalDepositLength++;
            }
        }

        return tempBridgeAdditionalDepositLength;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(0) {}

    function updateBridgeDepositInfo(
        uint256 tempBridgeLossLength,
        BridgeInteractionInfo[] memory tempBridgeLoss,
        BridgeInteractionInfo[] memory bridgeDepositInfo
    ) internal pure {
        for (uint256 index1 = 0; index1 < tempBridgeLossLength; index1++) {
            BridgeInteractionInfo memory tempBridgeLossElem = tempBridgeLoss[index1];
            for (uint256 index2 = 0; index2 < bridgeDepositInfo.length; index2++) {
                if (tempBridgeLossElem.bridge == bridgeDepositInfo[index2].bridge) {
                    bridgeDepositInfo[index2].amount -= tempBridgeLossElem.amount;
                    break;
                }
            }
        }
    }
}
