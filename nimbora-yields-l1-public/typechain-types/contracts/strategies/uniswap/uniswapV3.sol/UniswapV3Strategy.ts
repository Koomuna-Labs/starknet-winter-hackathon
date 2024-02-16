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
  EventFragment,
  AddressLike,
  ContractRunner,
  ContractMethod,
  Listener,
} from "ethers";
import type {
  TypedContractEvent,
  TypedDeferredTopicFilter,
  TypedEventLog,
  TypedLogDescription,
  TypedListener,
  TypedContractMethod,
} from "../../../../common";

export interface UniswapV3StrategyInterface extends Interface {
  getFunction(
    nameOrSignature:
      | "applySlippageDepositExactInputSingle"
      | "applySlippageWithdrawExactOutputSingle"
      | "chainlinkLatestAnswer"
      | "chainlinkPricefeed"
      | "handleReport"
      | "initialize"
      | "initializeStrategyBase"
      | "minReceivedAmountFactor"
      | "nav"
      | "paused"
      | "poolFee"
      | "poolingManager"
      | "pricefeedPrecision"
      | "setMinReceivedAmountFactor"
      | "underlyingToYield"
      | "underlyingToken"
      | "uniswapRouter"
      | "yieldBalance"
      | "yieldToUnderlying"
      | "yieldToken"
  ): FunctionFragment;

  getEvent(
    nameOrSignatureOrTopic: "Initialized" | "Paused" | "Unpaused"
  ): EventFragment;

  encodeFunctionData(
    functionFragment: "applySlippageDepositExactInputSingle",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "applySlippageWithdrawExactOutputSingle",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "chainlinkLatestAnswer",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "chainlinkPricefeed",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "handleReport",
    values: [BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "initialize",
    values: [
      AddressLike,
      AddressLike,
      AddressLike,
      AddressLike,
      AddressLike,
      AddressLike,
      BigNumberish,
      BigNumberish
    ]
  ): string;
  encodeFunctionData(
    functionFragment: "initializeStrategyBase",
    values: [AddressLike, AddressLike, AddressLike]
  ): string;
  encodeFunctionData(
    functionFragment: "minReceivedAmountFactor",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "nav", values?: undefined): string;
  encodeFunctionData(functionFragment: "paused", values?: undefined): string;
  encodeFunctionData(functionFragment: "poolFee", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "poolingManager",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "pricefeedPrecision",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "setMinReceivedAmountFactor",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "underlyingToYield",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "underlyingToken",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "uniswapRouter",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "yieldBalance",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "yieldToUnderlying",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "yieldToken",
    values?: undefined
  ): string;

  decodeFunctionResult(
    functionFragment: "applySlippageDepositExactInputSingle",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "applySlippageWithdrawExactOutputSingle",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "chainlinkLatestAnswer",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "chainlinkPricefeed",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "handleReport",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "initialize", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "initializeStrategyBase",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "minReceivedAmountFactor",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "nav", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "paused", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "poolFee", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "poolingManager",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "pricefeedPrecision",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "setMinReceivedAmountFactor",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "underlyingToYield",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "underlyingToken",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "uniswapRouter",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "yieldBalance",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "yieldToUnderlying",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "yieldToken", data: BytesLike): Result;
}

export namespace InitializedEvent {
  export type InputTuple = [version: BigNumberish];
  export type OutputTuple = [version: bigint];
  export interface OutputObject {
    version: bigint;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace PausedEvent {
  export type InputTuple = [account: AddressLike];
  export type OutputTuple = [account: string];
  export interface OutputObject {
    account: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export namespace UnpausedEvent {
  export type InputTuple = [account: AddressLike];
  export type OutputTuple = [account: string];
  export interface OutputObject {
    account: string;
  }
  export type Event = TypedContractEvent<InputTuple, OutputTuple, OutputObject>;
  export type Filter = TypedDeferredTopicFilter<Event>;
  export type Log = TypedEventLog<Event>;
  export type LogDescription = TypedLogDescription<Event>;
}

export interface UniswapV3Strategy extends BaseContract {
  connect(runner?: ContractRunner | null): UniswapV3Strategy;
  waitForDeployment(): Promise<this>;

  interface: UniswapV3StrategyInterface;

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

  applySlippageDepositExactInputSingle: TypedContractMethod<
    [amount: BigNumberish],
    [bigint],
    "view"
  >;

  applySlippageWithdrawExactOutputSingle: TypedContractMethod<
    [amount: BigNumberish],
    [bigint],
    "view"
  >;

  chainlinkLatestAnswer: TypedContractMethod<[], [bigint], "view">;

  chainlinkPricefeed: TypedContractMethod<[], [string], "view">;

  handleReport: TypedContractMethod<
    [actionId: BigNumberish, amount: BigNumberish],
    [[bigint, bigint]],
    "payable"
  >;

  initialize: TypedContractMethod<
    [
      _poolingManager: AddressLike,
      _underlyingToken: AddressLike,
      _yieldToken: AddressLike,
      _uniswapRouter: AddressLike,
      _uniswapFactory: AddressLike,
      _chainlinkPricefeed: AddressLike,
      _minReceivedAmountFactor: BigNumberish,
      _poolFee: BigNumberish
    ],
    [void],
    "nonpayable"
  >;

  initializeStrategyBase: TypedContractMethod<
    [
      _l2PoolingManager: AddressLike,
      _underlyingToken: AddressLike,
      _yieldToken: AddressLike
    ],
    [void],
    "nonpayable"
  >;

  minReceivedAmountFactor: TypedContractMethod<[], [bigint], "view">;

  nav: TypedContractMethod<[], [bigint], "view">;

  paused: TypedContractMethod<[], [boolean], "view">;

  poolFee: TypedContractMethod<[], [bigint], "view">;

  poolingManager: TypedContractMethod<[], [string], "view">;

  pricefeedPrecision: TypedContractMethod<[], [bigint], "view">;

  setMinReceivedAmountFactor: TypedContractMethod<
    [_minReceivedAmountFactor: BigNumberish],
    [void],
    "nonpayable"
  >;

  underlyingToYield: TypedContractMethod<
    [amount: BigNumberish],
    [bigint],
    "view"
  >;

  underlyingToken: TypedContractMethod<[], [string], "view">;

  uniswapRouter: TypedContractMethod<[], [string], "view">;

  yieldBalance: TypedContractMethod<[], [bigint], "view">;

  yieldToUnderlying: TypedContractMethod<
    [amount: BigNumberish],
    [bigint],
    "view"
  >;

  yieldToken: TypedContractMethod<[], [string], "view">;

  getFunction<T extends ContractMethod = ContractMethod>(
    key: string | FunctionFragment
  ): T;

  getFunction(
    nameOrSignature: "applySlippageDepositExactInputSingle"
  ): TypedContractMethod<[amount: BigNumberish], [bigint], "view">;
  getFunction(
    nameOrSignature: "applySlippageWithdrawExactOutputSingle"
  ): TypedContractMethod<[amount: BigNumberish], [bigint], "view">;
  getFunction(
    nameOrSignature: "chainlinkLatestAnswer"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "chainlinkPricefeed"
  ): TypedContractMethod<[], [string], "view">;
  getFunction(
    nameOrSignature: "handleReport"
  ): TypedContractMethod<
    [actionId: BigNumberish, amount: BigNumberish],
    [[bigint, bigint]],
    "payable"
  >;
  getFunction(
    nameOrSignature: "initialize"
  ): TypedContractMethod<
    [
      _poolingManager: AddressLike,
      _underlyingToken: AddressLike,
      _yieldToken: AddressLike,
      _uniswapRouter: AddressLike,
      _uniswapFactory: AddressLike,
      _chainlinkPricefeed: AddressLike,
      _minReceivedAmountFactor: BigNumberish,
      _poolFee: BigNumberish
    ],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "initializeStrategyBase"
  ): TypedContractMethod<
    [
      _l2PoolingManager: AddressLike,
      _underlyingToken: AddressLike,
      _yieldToken: AddressLike
    ],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "minReceivedAmountFactor"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "nav"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "paused"
  ): TypedContractMethod<[], [boolean], "view">;
  getFunction(
    nameOrSignature: "poolFee"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "poolingManager"
  ): TypedContractMethod<[], [string], "view">;
  getFunction(
    nameOrSignature: "pricefeedPrecision"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "setMinReceivedAmountFactor"
  ): TypedContractMethod<
    [_minReceivedAmountFactor: BigNumberish],
    [void],
    "nonpayable"
  >;
  getFunction(
    nameOrSignature: "underlyingToYield"
  ): TypedContractMethod<[amount: BigNumberish], [bigint], "view">;
  getFunction(
    nameOrSignature: "underlyingToken"
  ): TypedContractMethod<[], [string], "view">;
  getFunction(
    nameOrSignature: "uniswapRouter"
  ): TypedContractMethod<[], [string], "view">;
  getFunction(
    nameOrSignature: "yieldBalance"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "yieldToUnderlying"
  ): TypedContractMethod<[amount: BigNumberish], [bigint], "view">;
  getFunction(
    nameOrSignature: "yieldToken"
  ): TypedContractMethod<[], [string], "view">;

  getEvent(
    key: "Initialized"
  ): TypedContractEvent<
    InitializedEvent.InputTuple,
    InitializedEvent.OutputTuple,
    InitializedEvent.OutputObject
  >;
  getEvent(
    key: "Paused"
  ): TypedContractEvent<
    PausedEvent.InputTuple,
    PausedEvent.OutputTuple,
    PausedEvent.OutputObject
  >;
  getEvent(
    key: "Unpaused"
  ): TypedContractEvent<
    UnpausedEvent.InputTuple,
    UnpausedEvent.OutputTuple,
    UnpausedEvent.OutputObject
  >;

  filters: {
    "Initialized(uint64)": TypedContractEvent<
      InitializedEvent.InputTuple,
      InitializedEvent.OutputTuple,
      InitializedEvent.OutputObject
    >;
    Initialized: TypedContractEvent<
      InitializedEvent.InputTuple,
      InitializedEvent.OutputTuple,
      InitializedEvent.OutputObject
    >;

    "Paused(address)": TypedContractEvent<
      PausedEvent.InputTuple,
      PausedEvent.OutputTuple,
      PausedEvent.OutputObject
    >;
    Paused: TypedContractEvent<
      PausedEvent.InputTuple,
      PausedEvent.OutputTuple,
      PausedEvent.OutputObject
    >;

    "Unpaused(address)": TypedContractEvent<
      UnpausedEvent.InputTuple,
      UnpausedEvent.OutputTuple,
      UnpausedEvent.OutputObject
    >;
    Unpaused: TypedContractEvent<
      UnpausedEvent.InputTuple,
      UnpausedEvent.OutputTuple,
      UnpausedEvent.OutputObject
    >;
  };
}
