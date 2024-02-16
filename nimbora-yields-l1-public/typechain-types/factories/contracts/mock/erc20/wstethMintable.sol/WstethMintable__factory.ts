/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import {
  Contract,
  ContractFactory,
  ContractTransactionResponse,
  Interface,
} from "ethers";
import type {
  Signer,
  BigNumberish,
  ContractDeployTransaction,
  ContractRunner,
} from "ethers";
import type { NonPayableOverrides } from "../../../../../common";
import type {
  WstethMintable,
  WstethMintableInterface,
} from "../../../../../contracts/mock/erc20/wstethMintable.sol/WstethMintable";

const _abi = [
  {
    inputs: [
      {
        internalType: "uint256",
        name: "_stEthPerTokenValue",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "allowance",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "needed",
        type: "uint256",
      },
    ],
    name: "ERC20InsufficientAllowance",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "sender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "balance",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "needed",
        type: "uint256",
      },
    ],
    name: "ERC20InsufficientBalance",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "approver",
        type: "address",
      },
    ],
    name: "ERC20InvalidApprover",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "receiver",
        type: "address",
      },
    ],
    name: "ERC20InvalidReceiver",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "sender",
        type: "address",
      },
    ],
    name: "ERC20InvalidSender",
    type: "error",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
    ],
    name: "ERC20InvalidSpender",
    type: "error",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "Approval",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        indexed: true,
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "Transfer",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
      {
        internalType: "address",
        name: "spender",
        type: "address",
      },
    ],
    name: "allowance",
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
        internalType: "address",
        name: "spender",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "approve",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
    ],
    name: "balanceOf",
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
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "burn",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "decimals",
    outputs: [
      {
        internalType: "uint8",
        name: "",
        type: "uint8",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "account",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
    ],
    name: "mint",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "name",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "stEthPerToken",
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
    name: "stEthPerTokenValue",
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
    name: "symbol",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "totalSupply",
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
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "transfer",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
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
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        internalType: "uint256",
        name: "value",
        type: "uint256",
      },
    ],
    name: "transferFrom",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b50604051610a33380380610a3383398101604081905261002f91610098565b6040518060400160405280600a8152602001695773746574684d6f636b60b01b815250604051806040016040528060068152602001650eee6e8cae8d60d31b81525081600390816100809190610150565b50600461008d8282610150565b50505060055561020f565b6000602082840312156100aa57600080fd5b5051919050565b634e487b7160e01b600052604160045260246000fd5b600181811c908216806100db57607f821691505b6020821081036100fb57634e487b7160e01b600052602260045260246000fd5b50919050565b601f82111561014b57600081815260208120601f850160051c810160208610156101285750805b601f850160051c820191505b8181101561014757828155600101610134565b5050505b505050565b81516001600160401b03811115610169576101696100b1565b61017d8161017784546100c7565b84610101565b602080601f8311600181146101b2576000841561019a5750858301515b600019600386901b1c1916600185901b178555610147565b600085815260208120601f198616915b828110156101e1578886015182559484019460019091019084016101c2565b50858210156101ff5787850151600019600388901b60f8161c191681555b5050505050600190811b01905550565b6108158061021e6000396000f3fe608060405234801561001057600080fd5b50600436106100cf5760003560e01c806340c10f191161008c57806395d89b411161006657806395d89b41146101945780639dc29fac1461019c578063a9059cbb146101af578063dd62ed3e146101c257600080fd5b806340c10f191461014d57806370a0823114610162578063737874bb1461018b57600080fd5b8063035faf82146100d457806306fdde03146100eb578063095ea7b31461010057806318160ddd1461012357806323b872dd1461012b578063313ce5671461013e575b600080fd5b6005545b6040519081526020015b60405180910390f35b6100f36101fb565b6040516100e2919061065f565b61011361010e3660046106c9565b61028d565b60405190151581526020016100e2565b6002546100d8565b6101136101393660046106f3565b6102a7565b604051601281526020016100e2565b61016061015b3660046106c9565b6102cb565b005b6100d861017036600461072f565b6001600160a01b031660009081526020819052604090205490565b6100d860055481565b6100f36102d9565b6101606101aa3660046106c9565b6102e8565b6101136101bd3660046106c9565b6102f2565b6100d86101d0366004610751565b6001600160a01b03918216600090815260016020908152604080832093909416825291909152205490565b60606003805461020a90610784565b80601f016020809104026020016040519081016040528092919081815260200182805461023690610784565b80156102835780601f1061025857610100808354040283529160200191610283565b820191906000526020600020905b81548152906001019060200180831161026657829003601f168201915b5050505050905090565b60003361029b818585610300565b60019150505b92915050565b6000336102b5858285610312565b6102c0858585610395565b506001949350505050565b6102d582826103f4565b5050565b60606004805461020a90610784565b6102d5828261042a565b60003361029b818585610395565b61030d8383836001610460565b505050565b6001600160a01b03838116600090815260016020908152604080832093861683529290522054600019811461038f578181101561038057604051637dc7a0d960e11b81526001600160a01b038416600482015260248101829052604481018390526064015b60405180910390fd5b61038f84848484036000610460565b50505050565b6001600160a01b0383166103bf57604051634b637e8f60e11b815260006004820152602401610377565b6001600160a01b0382166103e95760405163ec442f0560e01b815260006004820152602401610377565b61030d838383610535565b6001600160a01b03821661041e5760405163ec442f0560e01b815260006004820152602401610377565b6102d560008383610535565b6001600160a01b03821661045457604051634b637e8f60e11b815260006004820152602401610377565b6102d582600083610535565b6001600160a01b03841661048a5760405163e602df0560e01b815260006004820152602401610377565b6001600160a01b0383166104b457604051634a1406b160e11b815260006004820152602401610377565b6001600160a01b038085166000908152600160209081526040808320938716835292905220829055801561038f57826001600160a01b0316846001600160a01b03167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b9258460405161052791815260200190565b60405180910390a350505050565b6001600160a01b03831661056057806002600082825461055591906107be565b909155506105d29050565b6001600160a01b038316600090815260208190526040902054818110156105b35760405163391434e360e21b81526001600160a01b03851660048201526024810182905260448101839052606401610377565b6001600160a01b03841660009081526020819052604090209082900390555b6001600160a01b0382166105ee5760028054829003905561060d565b6001600160a01b03821660009081526020819052604090208054820190555b816001600160a01b0316836001600160a01b03167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef8360405161065291815260200190565b60405180910390a3505050565b600060208083528351808285015260005b8181101561068c57858101830151858201604001528201610670565b506000604082860101526040601f19601f8301168501019250505092915050565b80356001600160a01b03811681146106c457600080fd5b919050565b600080604083850312156106dc57600080fd5b6106e5836106ad565b946020939093013593505050565b60008060006060848603121561070857600080fd5b610711846106ad565b925061071f602085016106ad565b9150604084013590509250925092565b60006020828403121561074157600080fd5b61074a826106ad565b9392505050565b6000806040838503121561076457600080fd5b61076d836106ad565b915061077b602084016106ad565b90509250929050565b600181811c9082168061079857607f821691505b6020821081036107b857634e487b7160e01b600052602260045260246000fd5b50919050565b808201808211156102a157634e487b7160e01b600052601160045260246000fdfea2646970667358221220371261b8db104940af52b866e4b76a934e07a3233a9d448181f17222e807401064736f6c63430008140033";

type WstethMintableConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: WstethMintableConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class WstethMintable__factory extends ContractFactory {
  constructor(...args: WstethMintableConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override getDeployTransaction(
    _stEthPerTokenValue: BigNumberish,
    overrides?: NonPayableOverrides & { from?: string }
  ): Promise<ContractDeployTransaction> {
    return super.getDeployTransaction(_stEthPerTokenValue, overrides || {});
  }
  override deploy(
    _stEthPerTokenValue: BigNumberish,
    overrides?: NonPayableOverrides & { from?: string }
  ) {
    return super.deploy(_stEthPerTokenValue, overrides || {}) as Promise<
      WstethMintable & {
        deploymentTransaction(): ContractTransactionResponse;
      }
    >;
  }
  override connect(runner: ContractRunner | null): WstethMintable__factory {
    return super.connect(runner) as WstethMintable__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): WstethMintableInterface {
    return new Interface(_abi) as WstethMintableInterface;
  }
  static connect(
    address: string,
    runner?: ContractRunner | null
  ): WstethMintable {
    return new Contract(address, _abi, runner) as unknown as WstethMintable;
  }
}