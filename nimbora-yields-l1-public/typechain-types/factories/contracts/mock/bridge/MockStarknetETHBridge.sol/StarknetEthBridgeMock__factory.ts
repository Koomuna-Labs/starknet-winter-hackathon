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
  StarknetEthBridgeMock,
  StarknetEthBridgeMockInterface,
} from "../../../../../contracts/mock/bridge/MockStarknetETHBridge.sol/StarknetEthBridgeMock";

const _abi = [
  {
    inputs: [
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
      {
        internalType: "uint256",
        name: "l2Recipient",
        type: "uint256",
      },
    ],
    name: "deposit",
    outputs: [],
    stateMutability: "payable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "amount",
        type: "uint256",
      },
      {
        internalType: "address",
        name: "recipient",
        type: "address",
      },
    ],
    name: "withdraw",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    stateMutability: "payable",
    type: "receive",
  },
] as const;

const _bytecode =
  "0x608060405234801561001057600080fd5b5061012b806100206000396000f3fe60806040526004361060295760003560e01c8062f714ce146034578063e2bbb15814605157600080fd5b36602f57005b600080fd5b348015603f57600080fd5b50604f604b366004609a565b6060565b005b604f605c36600460d4565b5050565b6040516001600160a01b0382169083156108fc029084906000818181858888f193505050501580156095573d6000803e3d6000fd5b505050565b6000806040838503121560ac57600080fd5b8235915060208301356001600160a01b038116811460c957600080fd5b809150509250929050565b6000806040838503121560e657600080fd5b5050803592602090910135915056fea26469706673582212209f2d9c77ba91309341b4866eae2d3bce9188d63f63d30b0b49c3045719b30a2b64736f6c63430008140033";

type StarknetEthBridgeMockConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: StarknetEthBridgeMockConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class StarknetEthBridgeMock__factory extends ContractFactory {
  constructor(...args: StarknetEthBridgeMockConstructorParams) {
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
      StarknetEthBridgeMock & {
        deploymentTransaction(): ContractTransactionResponse;
      }
    >;
  }
  override connect(
    runner: ContractRunner | null
  ): StarknetEthBridgeMock__factory {
    return super.connect(runner) as StarknetEthBridgeMock__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): StarknetEthBridgeMockInterface {
    return new Interface(_abi) as StarknetEthBridgeMockInterface;
  }
  static connect(
    address: string,
    runner?: ContractRunner | null
  ): StarknetEthBridgeMock {
    return new Contract(
      address,
      _abi,
      runner
    ) as unknown as StarknetEthBridgeMock;
  }
}
