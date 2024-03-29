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
} from "../../common";

export interface StrategyBaseInterface extends Interface {
  getFunction(
    nameOrSignature:
      | "handleReport"
      | "initializeStrategyBase"
      | "nav"
      | "paused"
      | "poolingManager"
      | "underlyingToYield"
      | "underlyingToken"
      | "yieldBalance"
      | "yieldToUnderlying"
      | "yieldToken"
  ): FunctionFragment;

  getEvent(
    nameOrSignatureOrTopic: "Initialized" | "Paused" | "Unpaused"
  ): EventFragment;

  encodeFunctionData(
    functionFragment: "handleReport",
    values: [BigNumberish, BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "initializeStrategyBase",
    values: [AddressLike, AddressLike, AddressLike]
  ): string;
  encodeFunctionData(functionFragment: "nav", values?: undefined): string;
  encodeFunctionData(functionFragment: "paused", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "poolingManager",
    values?: undefined
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
    functionFragment: "handleReport",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "initializeStrategyBase",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "nav", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "paused", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "poolingManager",
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

export interface StrategyBase extends BaseContract {
  connect(runner?: ContractRunner | null): StrategyBase;
  waitForDeployment(): Promise<this>;

  interface: StrategyBaseInterface;

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

  handleReport: TypedContractMethod<
    [actionId: BigNumberish, amount: BigNumberish],
    [[bigint, bigint]],
    "payable"
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

  nav: TypedContractMethod<[], [bigint], "view">;

  paused: TypedContractMethod<[], [boolean], "view">;

  poolingManager: TypedContractMethod<[], [string], "view">;

  underlyingToYield: TypedContractMethod<
    [amount: BigNumberish],
    [bigint],
    "view"
  >;

  underlyingToken: TypedContractMethod<[], [string], "view">;

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
    nameOrSignature: "handleReport"
  ): TypedContractMethod<
    [actionId: BigNumberish, amount: BigNumberish],
    [[bigint, bigint]],
    "payable"
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
    nameOrSignature: "nav"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "paused"
  ): TypedContractMethod<[], [boolean], "view">;
  getFunction(
    nameOrSignature: "poolingManager"
  ): TypedContractMethod<[], [string], "view">;
  getFunction(
    nameOrSignature: "underlyingToYield"
  ): TypedContractMethod<[amount: BigNumberish], [bigint], "view">;
  getFunction(
    nameOrSignature: "underlyingToken"
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
