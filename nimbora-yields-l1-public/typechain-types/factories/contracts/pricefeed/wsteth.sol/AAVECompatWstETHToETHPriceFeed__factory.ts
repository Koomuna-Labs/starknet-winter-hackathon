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
  AddressLike,
  ContractDeployTransaction,
  ContractRunner,
} from "ethers";
import type { NonPayableOverrides } from "../../../../common";
import type {
  AAVECompatWstETHToETHPriceFeed,
  AAVECompatWstETHToETHPriceFeedInterface,
} from "../../../../contracts/pricefeed/wsteth.sol/AAVECompatWstETHToETHPriceFeed";

const _abi = [
  {
    inputs: [
      {
        internalType: "address",
        name: "_stETHToETHPriceFeed",
        type: "address",
      },
      {
        internalType: "address",
        name: "_wstETH",
        type: "address",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    stateMutability: "nonpayable",
    type: "fallback",
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
    stateMutability: "pure",
    type: "function",
  },
  {
    inputs: [],
    name: "latestAnswer",
    outputs: [
      {
        internalType: "int256",
        name: "",
        type: "int256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "stETHToETHPriceFeed",
    outputs: [
      {
        internalType: "contract IChainlinkAggregator",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "wstETH",
    outputs: [
      {
        internalType: "contract IWstETH",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
] as const;

const _bytecode =
  "0x60c060405234801561001057600080fd5b5060405161041c38038061041c83398101604081905261002f91610062565b6001600160a01b0391821660a05216608052610095565b80516001600160a01b038116811461005d57600080fd5b919050565b6000806040838503121561007557600080fd5b61007e83610046565b915061008c60208401610046565b90509250929050565b60805160a0516103566100c660003960008181609d01526101c301526000818160f0015261012d01526103566000f3fe608060405234801561001057600080fd5b506004361061004c5760003560e01c80632c92d3bb14610098578063313ce567146100dc5780634aa07e64146100eb57806350d25bcd14610112575b60405162461bcd60e51b815260206004820152601960248201527f556e65787065637465642066756e6374696f6e2063616c6c2e00000000000000604482015260640160405180910390fd5b6100bf7f000000000000000000000000000000000000000000000000000000000000000081565b6040516001600160a01b0390911681526020015b60405180910390f35b604051601281526020016100d3565b6100bf7f000000000000000000000000000000000000000000000000000000000000000081565b61011a610128565b6040519081526020016100d3565b6000807f00000000000000000000000000000000000000000000000000000000000000006001600160a01b031663035faf826040518163ffffffff1660e01b8152600401602060405180830381865afa158015610189573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906101ad9190610269565b9050600081136101bf576101bf610282565b60007f00000000000000000000000000000000000000000000000000000000000000006001600160a01b03166350d25bcd6040518163ffffffff1660e01b8152600401602060405180830381865afa15801561021f573d6000803e3d6000fd5b505050506040513d601f19601f820116820180604052508101906102439190610269565b9050670de0b6b3a764000061025882846102ae565b61026291906102e4565b9250505090565b60006020828403121561027b57600080fd5b5051919050565b634e487b7160e01b600052600160045260246000fd5b634e487b7160e01b600052601160045260246000fd5b80820260008212600160ff1b841416156102ca576102ca610298565b81810583148215176102de576102de610298565b92915050565b60008261030157634e487b7160e01b600052601260045260246000fd5b600160ff1b82146000198414161561031b5761031b610298565b50059056fea2646970667358221220b84d13db2e38ebf355122382aac2683f80352f10cf5608b0cd2c3a279f05551c64736f6c63430008140033";

type AAVECompatWstETHToETHPriceFeedConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: AAVECompatWstETHToETHPriceFeedConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class AAVECompatWstETHToETHPriceFeed__factory extends ContractFactory {
  constructor(...args: AAVECompatWstETHToETHPriceFeedConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override getDeployTransaction(
    _stETHToETHPriceFeed: AddressLike,
    _wstETH: AddressLike,
    overrides?: NonPayableOverrides & { from?: string }
  ): Promise<ContractDeployTransaction> {
    return super.getDeployTransaction(
      _stETHToETHPriceFeed,
      _wstETH,
      overrides || {}
    );
  }
  override deploy(
    _stETHToETHPriceFeed: AddressLike,
    _wstETH: AddressLike,
    overrides?: NonPayableOverrides & { from?: string }
  ) {
    return super.deploy(
      _stETHToETHPriceFeed,
      _wstETH,
      overrides || {}
    ) as Promise<
      AAVECompatWstETHToETHPriceFeed & {
        deploymentTransaction(): ContractTransactionResponse;
      }
    >;
  }
  override connect(
    runner: ContractRunner | null
  ): AAVECompatWstETHToETHPriceFeed__factory {
    return super.connect(runner) as AAVECompatWstETHToETHPriceFeed__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): AAVECompatWstETHToETHPriceFeedInterface {
    return new Interface(_abi) as AAVECompatWstETHToETHPriceFeedInterface;
  }
  static connect(
    address: string,
    runner?: ContractRunner | null
  ): AAVECompatWstETHToETHPriceFeed {
    return new Contract(
      address,
      _abi,
      runner
    ) as unknown as AAVECompatWstETHToETHPriceFeed;
  }
}
