/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Interface, type ContractRunner } from "ethers";
import type {
  IStarknetMessaging,
  IStarknetMessagingInterface,
} from "../../../contracts/interfaces/IStarknetMessaging";

const _abi = [
  {
    inputs: [
      {
        internalType: "uint256",
        name: "fromAddress",
        type: "uint256",
      },
      {
        internalType: "uint256[]",
        name: "payload",
        type: "uint256[]",
      },
    ],
    name: "consumeMessageFromL2",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes32",
        name: "msgHash",
        type: "bytes32",
      },
    ],
    name: "l2ToL1Messages",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "toAddress",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "selector",
        type: "uint256",
      },
      {
        internalType: "uint256[]",
        name: "payload",
        type: "uint256[]",
      },
    ],
    name: "sendMessageToL2",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "payable",
    type: "function",
  },
] as const;

export class IStarknetMessaging__factory {
  static readonly abi = _abi;
  static createInterface(): IStarknetMessagingInterface {
    return new Interface(_abi) as IStarknetMessagingInterface;
  }
  static connect(
    address: string,
    runner?: ContractRunner | null
  ): IStarknetMessaging {
    return new Contract(address, _abi, runner) as unknown as IStarknetMessaging;
  }
}
