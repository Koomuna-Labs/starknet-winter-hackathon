/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import {
  Contract,
  ContractFactory,
  ContractTransactionResponse,
  Interface,
} from "ethers";
import type { Signer, ContractDeployTransaction, ContractRunner } from "ethers";
import type { NonPayableOverrides } from "../../../../../common";
import type {
  StarknetMock,
  StarknetMockInterface,
} from "../../../../../contracts/mock/starknet/starknetMock.sol/StarknetMock";

const _abi = [
  {
    inputs: [
      {
        internalType: "bytes32[]",
        name: "msgHashes",
        type: "bytes32[]",
      },
    ],
    name: "addMessage",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
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
        internalType: "address",
        name: "from",
        type: "address",
      },
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
      {
        internalType: "uint256",
        name: "nonce",
        type: "uint256",
      },
    ],
    name: "getL1ToL2MsgHash",
    outputs: [
      {
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "l1ToL2MessageNonce",
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
        internalType: "bytes32",
        name: "",
        type: "bytes32",
      },
    ],
    name: "l1ToL2Messages",
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
        internalType: "bytes32",
        name: "",
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

const _bytecode =
  "0x608060405234801561001057600080fd5b50610762806100206000396000f3fe6080604052600436106100705760003560e01c806377c7d7a91161004e57806377c7d7a9146100e6578063a46efaf314610113578063f0237a8914610140578063f167badd1461016057600080fd5b8063018cccdf146100755780632c9dd5c01461009e5780633e3aa6c5146100be575b600080fd5b34801561008157600080fd5b5061008b60025481565b6040519081526020015b60405180910390f35b3480156100aa57600080fd5b5061008b6100b9366004610426565b610182565b6100d16100cc366004610472565b610245565b60408051928352602083019190915201610095565b3480156100f257600080fd5b5061008b6101013660046104c5565b60016020526000908152604090205481565b34801561011f57600080fd5b5061008b61012e3660046104c5565b60006020819052908152604090205481565b34801561014c57600080fd5b5061008b61015b3660046104de565b6102ea565b34801561016c57600080fd5b5061018061017b366004610572565b610335565b005b60405160009081906101a09086903390869088908290602001610659565b60408051601f1981840301815291815281516020928301206000818152928390529120549091506102185760405162461bcd60e51b815260206004820152601a60248201527f494e56414c49445f4d4553534147455f544f5f434f4e53554d4500000000000060448201526064015b60405180910390fd5b6000818152602081905260408120805460019290610237908490610699565b909155509095945050505050565b600080600034116102a25760405162461bcd60e51b815260206004820152602160248201527f4c315f4d53475f4645455f4d5553545f42455f475245415445525f5448414e5f6044820152600360fc1b606482015260840161020f565b6002546102b08160016106b2565b60025560006102c28888888886610399565b90506102cf3460016106b2565b60008281526001602052604090205597909650945050505050565b604051600090610313906001600160a01b0389169088908590899088908a9082906020016106c5565b6040516020818303038152906040528051906020012090509695505050505050565b60005b8151811015610395576001600080848481518110610358576103586106fd565b60200260200101518152602001908152602001600020600082825461037d91906106b2565b9091555081905061038d81610713565b915050610338565b5050565b6040516000906103b990339088908590899088908a9082906020016106c5565b60405160208183030381529060405280519060200120905095945050505050565b60008083601f8401126103ec57600080fd5b50813567ffffffffffffffff81111561040457600080fd5b6020830191508360208260051b850101111561041f57600080fd5b9250929050565b60008060006040848603121561043b57600080fd5b83359250602084013567ffffffffffffffff81111561045957600080fd5b610465868287016103da565b9497909650939450505050565b6000806000806060858703121561048857600080fd5b8435935060208501359250604085013567ffffffffffffffff8111156104ad57600080fd5b6104b9878288016103da565b95989497509550505050565b6000602082840312156104d757600080fd5b5035919050565b60008060008060008060a087890312156104f757600080fd5b86356001600160a01b038116811461050e57600080fd5b95506020870135945060408701359350606087013567ffffffffffffffff81111561053857600080fd5b61054489828a016103da565b979a9699509497949695608090950135949350505050565b634e487b7160e01b600052604160045260246000fd5b6000602080838503121561058557600080fd5b823567ffffffffffffffff8082111561059d57600080fd5b818501915085601f8301126105b157600080fd5b8135818111156105c3576105c361055c565b8060051b604051601f19603f830116810181811085821117156105e8576105e861055c565b60405291825284820192508381018501918883111561060657600080fd5b938501935b828510156106245784358452938501939285019261060b565b98975050505050505050565b60006001600160fb1b0383111561064657600080fd5b8260051b80838637939093019392505050565b8581528460208201528360408201526000610678606083018486610630565b979650505050505050565b634e487b7160e01b600052601160045260246000fd5b818103818111156106ac576106ac610683565b92915050565b808201808211156106ac576106ac610683565b87815286602082015285604082015284606082015283608082015260006106f060a083018486610630565b9998505050505050505050565b634e487b7160e01b600052603260045260246000fd5b60006001820161072557610725610683565b506001019056fea264697066735822122049a719ae7c5b79261e0f6a9c20f3e889405af02b7765ba7b71c4dc32a0a3127764736f6c63430008140033";

type StarknetMockConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: StarknetMockConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class StarknetMock__factory extends ContractFactory {
  constructor(...args: StarknetMockConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override getDeployTransaction(
    overrides?: NonPayableOverrides & { from?: string }
  ): Promise<ContractDeployTransaction> {
    return super.getDeployTransaction(overrides || {});
  }
  override deploy(overrides?: NonPayableOverrides & { from?: string }) {
    return super.deploy(overrides || {}) as Promise<
      StarknetMock & {
        deploymentTransaction(): ContractTransactionResponse;
      }
    >;
  }
  override connect(runner: ContractRunner | null): StarknetMock__factory {
    return super.connect(runner) as StarknetMock__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): StarknetMockInterface {
    return new Interface(_abi) as StarknetMockInterface;
  }
  static connect(
    address: string,
    runner?: ContractRunner | null
  ): StarknetMock {
    return new Contract(address, _abi, runner) as unknown as StarknetMock;
  }
}
