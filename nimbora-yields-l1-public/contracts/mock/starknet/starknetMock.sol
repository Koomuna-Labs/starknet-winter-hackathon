//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract StarknetMock {
    mapping(bytes32 => uint256) public l2ToL1Messages;
    mapping(bytes32 => uint256) public l1ToL2Messages;
    uint256 public l1ToL2MessageNonce;

    function addMessage(bytes32[] memory msgHashes) external {
        for (uint256 i = 0; i < msgHashes.length; i++) {
            l2ToL1Messages[msgHashes[i]] += 1;
        }
    }

    function consumeMessageFromL2(uint256 fromAddress, uint256[] calldata payload) external returns (bytes32) {
        bytes32 msgHash = keccak256(
            abi.encodePacked(fromAddress, uint256(uint160(msg.sender)), payload.length, payload)
        );

        require(l2ToL1Messages[msgHash] > 0, "INVALID_MESSAGE_TO_CONSUME");
        l2ToL1Messages[msgHash] -= 1;
        return msgHash;
    }

    function sendMessageToL2(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload
    ) external payable returns (bytes32, uint256) {
        require(msg.value > 0, "L1_MSG_FEE_MUST_BE_GREATER_THAN_0");
        uint256 nonce = l1ToL2MessageNonce;
        l1ToL2MessageNonce = nonce + 1;
        bytes32 msgHash = getL1ToL2MsgHash(toAddress, selector, payload, nonce);
        // assert(
        //     msgHash ==
        //         0x6ccb65d433aedf74020e9ee5330713c5b11cf2da546519d32eab4d00c5c94e35
        // );
        l1ToL2Messages[msgHash] = msg.value + 1;
        return (msgHash, nonce);
    }

    function getL1ToL2MsgHash(
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) internal view returns (bytes32) {
        // assert(0x8e264821AFa98DD104eEcfcfa7FD9f8D8B320adA == msg.sender);
        // assert(toAddress == 1029302920393029293);
        // assert(
        //     selector ==
        //         0x10e13e50cb99b6b3c8270ec6e16acfccbe1164a629d74b43549567a77593aff
        // );
        // assert(payload.length == 4);
        // assert(payload[0] == 1);
        // assert(payload[1] == 0);
        // assert(payload[2] == 108435438677142185061741940086249401528);
        // assert(payload[3] == 124329071714117678877788791808645380031);
        // assert(nonce == 0);

        return
            keccak256(
                abi.encodePacked(uint256(uint160(msg.sender)), toAddress, nonce, selector, payload.length, payload)
            );
    }

    function getL1ToL2MsgHash(
        address from,
        uint256 toAddress,
        uint256 selector,
        uint256[] calldata payload,
        uint256 nonce
    ) external view returns (bytes32) {
        return keccak256(abi.encodePacked(uint256(uint160(from)), toAddress, nonce, selector, payload.length, payload));
    }
}
