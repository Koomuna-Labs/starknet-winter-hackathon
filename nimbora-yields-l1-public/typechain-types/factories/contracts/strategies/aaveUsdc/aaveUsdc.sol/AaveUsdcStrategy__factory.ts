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
  AaveUsdcStrategy,
  AaveUsdcStrategyInterface,
} from "../../../../../contracts/strategies/aaveUsdc/aaveUsdc.sol/AaveUsdcStrategy";

const _abi = [
  {
    inputs: [],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [],
    name: "EnforcedPause",
    type: "error",
  },
  {
    inputs: [],
    name: "ExpectedPause",
    type: "error",
  },
  {
    inputs: [],
    name: "InvalidCaller",
    type: "error",
  },
  {
    inputs: [],
    name: "InvalidInitialization",
    type: "error",
  },
  {
    inputs: [],
    name: "NotInitializing",
    type: "error",
  },
  {
    inputs: [],
    name: "UnknownActionId",
    type: "error",
  },
  {
    inputs: [],
    name: "ZeroAddress",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint64",
        name: "version",
        type: "uint64",
      },
    ],
    name: "Initialized",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "Paused",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "Unpaused",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "actionId",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "handleReport",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
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
  {
    inputs: [
      {
        internalType: "address",
        name: "_poolingManager",
        type: "address",
      },
      {
        internalType: "address",
        name: "_underlyingToken",
        type: "address",
      },
      {
        internalType: "address",
        name: "_yieldToken",
        type: "address",
      },
    ],
    name: "initialize",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "_l2PoolingManager",
        type: "address",
      },
      {
        internalType: "address",
        name: "_underlyingToken",
        type: "address",
      },
      {
        internalType: "address",
        name: "_yieldToken",
        type: "address",
      },
    ],
    name: "initializeStrategyBase",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "nav",
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
    inputs: [],
    name: "paused",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "poolingManager",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "underlyingToYield",
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
    inputs: [],
    name: "underlyingToken",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "yieldBalance",
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
        name: "amount",
        type: "uint256",
      },
    ],
    name: "yieldToUnderlying",
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
    inputs: [],
    name: "yieldToken",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b507ff0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00805468010000000000000000810460ff1615906001600160401b031660008115801561005b5750825b90506000826001600160401b031660011480156100775750303b155b905081158015610085575080155b156100a35760405163f92ee8a960e01b815260040160405180910390fd5b84546001600160401b031916600117855583156100d157845460ff60401b1916680100000000000000001785555b831561011757845460ff60401b19168555604051600181527fc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d29060200160405180910390a15b5050505050610c698061012b6000396000f3fe60806040526004361061009c5760003560e01c80639d1ea42c116100645780639d1ea42c14610190578063c0c53b8b146101b8578063c1590cd7146101d8578063cf062f0d146101ed578063d7f7080314610202578063dfa10b331461022257600080fd5b80632495a599146100a15780635c975abb146100de57806376d5de8514610120578063808a9df81461014057806383ce2b3414610162575b600080fd5b3480156100ad57600080fd5b506001546100c1906001600160a01b031681565b6040516001600160a01b0390911681526020015b60405180910390f35b3480156100ea57600080fd5b507fcd5ed15c6e187e77e9aee88184c21f4f2182ab5827cb3b7e07fbedcd63f033005460ff1660405190151581526020016100d5565b34801561012c57600080fd5b506002546100c1906001600160a01b031681565b34801561014c57600080fd5b5061016061015b366004610b4e565b610242565b005b34801561016e57600080fd5b5061018261017d366004610b99565b610406565b6040519081526020016100d5565b6101a361019e366004610bb2565b610417565b604080519283526020830191909152016100d5565b3480156101c457600080fd5b506101606101d3366004610b4e565b61048b565b3480156101e457600080fd5b5061018261059b565b3480156101f957600080fd5b506101826105aa565b34801561020e57600080fd5b506000546100c1906001600160a01b031681565b34801561022e57600080fd5b5061018261023d366004610b99565b610617565b7ff0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a008054600160401b810460ff16159067ffffffffffffffff166000811580156102885750825b905060008267ffffffffffffffff1660011480156102a55750303b155b9050811580156102b3575080155b156102d15760405163f92ee8a960e01b815260040160405180910390fd5b845467ffffffffffffffff1916600117855583156102fb57845460ff60401b1916600160401b1785555b610303610622565b6001600160a01b03881661032a5760405163d92e233d60e01b815260040160405180910390fd5b6001600160a01b0387166103515760405163d92e233d60e01b815260040160405180910390fd5b6001600160a01b0386166103785760405163d92e233d60e01b815260040160405180910390fd5b600080546001600160a01b03808b166001600160a01b031992831617909255600180548a8416908316179055600280549289169290911691909117905583156103fc57845460ff60401b19168555604051600181527fc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2906020015b60405180910390a15b5050505050505050565b600061041182610634565b92915050565b6000806104226106a3565b61042a6106e6565b60008461043f5761043a84610711565b610479565b60028503610457576104508461078a565b9050610479565b6001850315610479576040516308c4d1d560e01b815260040160405180910390fd5b610481610927565b9590945092505050565b7ff0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a008054600160401b810460ff16159067ffffffffffffffff166000811580156104d15750825b905060008267ffffffffffffffff1660011480156104ee5750303b155b9050811580156104fc575080155b1561051a5760405163f92ee8a960e01b815260040160405180910390fd5b845467ffffffffffffffff19166001178555831561054457845460ff60401b1916600160401b1785555b61054f888888610242565b6105598787610939565b83156103fc57845460ff60401b19168555604051600181527fc7f505b2f371ae2175ee4913f4499e1f2633a7b5936321eed1cdaeb6115181d2906020016103f3565b60006105a5610927565b905090565b6002546040516370a0823160e01b81523060048201526000916001600160a01b0316906370a0823190602401602060405180830381865afa1580156105f3573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906105a59190610bd4565b600061041182610a88565b61062a610aba565b610632610b03565b565b60025460405163ef8b30f760e01b8152600481018390526000916001600160a01b03169063ef8b30f7906024015b602060405180830381865afa15801561067f573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906104119190610bd4565b7fcd5ed15c6e187e77e9aee88184c21f4f2182ab5827cb3b7e07fbedcd63f033005460ff16156106325760405163d93c066560e01b815260040160405180910390fd5b6000546001600160a01b03163314610632576040516348f5c3ed60e01b815260040160405180910390fd5b600254604051636e553f6560e01b8152600481018390523060248201526001600160a01b0390911690636e553f65906044016020604051808303816000875af1158015610762573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906107869190610bd4565b5050565b600254604051630a28a47760e01b81526004810183905260009182916001600160a01b0390911690630a28a47790602401602060405180830381865afa1580156107d8573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906107fc9190610bd4565b905060006108086105aa565b90508082111561089c5760025460008054604051635d043b2960e11b8152600481018590526001600160a01b0391821660248201523060448201529192169063ba087652906064016020604051808303816000875af115801561086f573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906108939190610bd4565b95945050505050565b60025460008054604051632d182be560e21b8152600481018890526001600160a01b0391821660248201523060448201529192169063b460af94906064016020604051808303816000875af11580156108f9573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061091d9190610bd4565b5093949350505050565b60006105a56109346105aa565b610a88565b6000816001600160a01b0316633e413bee6040518163ffffffff1660e01b8152600401602060405180830381865afa158015610979573d6000803e3d6000fd5b505050506040513d601f19601f8201168201806040525081019061099d9190610bed565b9050826001600160a01b0316816001600160a01b031614610a0e5760405162461bcd60e51b815260206004820152602160248201527f496e76616c696420756e6465726c79696e673a204161766520537472617465676044820152607960f81b606482015260840160405180910390fd5b60405163095ea7b360e01b81526001600160a01b038381166004830152600019602483015284169063095ea7b3906044016020604051808303816000875af1158015610a5e573d6000803e3d6000fd5b505050506040513d601f19601f82011682018060405250810190610a829190610c11565b50505050565b60025460405163266d6a8360e11b8152600481018390526000916001600160a01b031690634cdad50690602401610662565b7ff0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a0054600160401b900460ff1661063257604051631afcd79f60e31b815260040160405180910390fd5b610b0b610aba565b7fcd5ed15c6e187e77e9aee88184c21f4f2182ab5827cb3b7e07fbedcd63f03300805460ff19169055565b6001600160a01b0381168114610b4b57600080fd5b50565b600080600060608486031215610b6357600080fd5b8335610b6e81610b36565b92506020840135610b7e81610b36565b91506040840135610b8e81610b36565b809150509250925092565b600060208284031215610bab57600080fd5b5035919050565b60008060408385031215610bc557600080fd5b50508035926020909101359150565b600060208284031215610be657600080fd5b5051919050565b600060208284031215610bff57600080fd5b8151610c0a81610b36565b9392505050565b600060208284031215610c2357600080fd5b81518015158114610c0a57600080fdfea26469706673582212206c57fd6e166fc902e5e8417ccd7647298d4d371470c06aadfc8125e53a69d96064736f6c63430008140033";

type AaveUsdcStrategyConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: AaveUsdcStrategyConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class AaveUsdcStrategy__factory extends ContractFactory {
  constructor(...args: AaveUsdcStrategyConstructorParams) {
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
      AaveUsdcStrategy & {
        deploymentTransaction(): ContractTransactionResponse;
      }
    >;
  }
  override connect(runner: ContractRunner | null): AaveUsdcStrategy__factory {
    return super.connect(runner) as AaveUsdcStrategy__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): AaveUsdcStrategyInterface {
    return new Interface(_abi) as AaveUsdcStrategyInterface;
  }
  static connect(
    address: string,
    runner?: ContractRunner | null
  ): AaveUsdcStrategy {
    return new Contract(address, _abi, runner) as unknown as AaveUsdcStrategy;
  }
}
