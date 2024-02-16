/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import type {
  BaseContract,
  BigNumberish,
  BytesLike,
  FunctionFragment,
  Result,
  Interface,
  AddressLike,
  ContractRunner,
  ContractMethod,
  Listener,
} from "ethers";
import type {
  TypedContractEvent,
  TypedDeferredTopicFilter,
  TypedEventLog,
  TypedListener,
  TypedContractMethod,
} from "../../common";

export interface IStarknetBridgeInterface extends Interface {
  getFunction(
    nameOrSignature:
      | "deposit"
      | "depositCancelRequest"
      | "depositReclaim"
      | "withdraw"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "deposit",
    values: [BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "depositCancelRequest",
    values: [BigNumberish, BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "depositReclaim",
    values: [BigNumberish, BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "withdraw",
    values: [BigNumberish, AddressLike]
  ): string;

  decodeFunctionResult(functionFragment: "deposit", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "depositCancelRequest",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "depositReclaim",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "withdraw", data: BytesLike): Result;
}

export interface IStarknetBridge extends BaseContract {
  connect(runner?: ContractRunner | null): IStarknetBridge;
  waitForDeployment(): Promise<this>;

  interface: IStarknetBridgeInterface;

  queryFilter<TCEvent extends TypedContractEvent>(
    event: TCEvent,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TypedEventLog<TCEvent>>>;
  queryFilter<TCEvent extends TypedContractEvent>(
    filter: TypedDeferredTopicFilter<TCEvent>,
    fromBlockOrBlockhash?: string | number | undefined,
    toBlock?: string | number | undefined
  ): Promise<Array<TypedEventLog<TCEvent>>>;

  on<TCEvent extends TypedContractEvent>(
    event: TCEvent,
    listener: TypedListener<TCEvent>
  ): Promise<this>;
  on<TCEvent extends TypedContractEvent>(
    filter: TypedDeferredTopicFilter<TCEvent>,
    listener: TypedListener<TCEvent>
  ): Promise<this>;

  once<TCEvent extends TypedContractEvent>(
    event: TCEvent,
    listener: TypedListener<TCEvent>
  ): Promise<this>;
  once<TCEvent extends TypedContractEvent>(
    filter: TypedDeferredTopicFilter<TCEvent>,
    listener: TypedListener<TCEvent>
  ): Promise<this>;

  listeners<TCEvent extends TypedContractEvent>(
    event: TCEvent
  ): Promise<Array<TypedListener<TCEvent>>>;
  listeners(eventName?: string): Promise<Array<Listener>>;
  removeAllListeners<TCEvent extends TypedContractEvent>(
    event?: TCEvent
  ): Promise<this>;

  deposit: TypedContractMethod<
    [amount: BigNumberish, l2Recipient: BigNumberish],
    [void],
    "payable"
  >;

  depositCancelRequest: TypedContractMethod<
    [amount: BigNumberish, l2Recipient: BigNumberish, nonce: BigNumberish],
    [void],
    "nonpayable"
  >;

  depositReclaim: TypedContractMethod<
    [amount: BigNumberish, l2Recipient: BigNumberish, nonce: BigNumberish],
    [void],
    "nonpayable"
  >;

  withdraw: TypedContractMethod<
    [amount: BigNumberish, recipient: AddressLike],
    [void],
    "nonpayable"
  >;

  getFunction<T extends ContractMethod = ContractMethod>(
    key: string | FunctionFragment
  ): T;

  getFunction(
    nameOrSignature: "deposit"
  ): TypedContractMethod<
    [amount: BigNumberish, l2Recipient: BigNumberish],
    [void],
    "payable"
  >;
  getFunction(
    nameOrSignature: "depositCancelRequest"
  ): TypedContractMethod<
    [amount: BigNumberish, l2Recipient: BigNumberish, nonce: BigNumberish],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "depositReclaim"
  ): TypedContractMethod<
    [amount: BigNumberish, l2Recipient: BigNumberish, nonce: BigNumberish],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "withdraw"
  ): TypedContractMethod<
    [amount: BigNumberish, recipient: AddressLike],
    [void],
    "nonpayable"
  >;

  filters: {};
}