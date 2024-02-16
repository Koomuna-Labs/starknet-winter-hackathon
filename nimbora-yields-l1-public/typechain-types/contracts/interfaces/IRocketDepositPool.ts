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

export interface IRocketDepositPoolInterface extends Interface {
  getFunction(
    nameOrSignature:
      | "assignDeposits"
      | "deposit"
      | "getBalance"
      | "getExcessBalance"
      | "getMaximumDepositAmount"
      | "getNodeBalance"
      | "getUserBalance"
      | "maybeAssignDeposits"
      | "nodeCreditWithdrawal"
      | "nodeDeposit"
      | "recycleDissolvedDeposit"
      | "recycleExcessCollateral"
      | "recycleLiquidatedStake"
      | "withdrawExcessBalance"
  ): FunctionFragment;

  encodeFunctionData(
    functionFragment: "assignDeposits",
    values?: undefined
  ): string;
  encodeFunctionData(functionFragment: "deposit", values?: undefined): string;
  encodeFunctionData(
    functionFragment: "getBalance",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getExcessBalance",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getMaximumDepositAmount",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getNodeBalance",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "getUserBalance",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "maybeAssignDeposits",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "nodeCreditWithdrawal",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "nodeDeposit",
    values: [BigNumberish]
  ): string;
  encodeFunctionData(
    functionFragment: "recycleDissolvedDeposit",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "recycleExcessCollateral",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "recycleLiquidatedStake",
    values?: undefined
  ): string;
  encodeFunctionData(
    functionFragment: "withdrawExcessBalance",
    values: [BigNumberish]
  ): string;

  decodeFunctionResult(
    functionFragment: "assignDeposits",
    data: BytesLike
  ): Result;
  decodeFunctionResult(functionFragment: "deposit", data: BytesLike): Result;
  decodeFunctionResult(functionFragment: "getBalance", data: BytesLike): Result;
  decodeFunctionResult(
    functionFragment: "getExcessBalance",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getMaximumDepositAmount",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getNodeBalance",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "getUserBalance",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "maybeAssignDeposits",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "nodeCreditWithdrawal",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "nodeDeposit",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "recycleDissolvedDeposit",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "recycleExcessCollateral",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "recycleLiquidatedStake",
    data: BytesLike
  ): Result;
  decodeFunctionResult(
    functionFragment: "withdrawExcessBalance",
    data: BytesLike
  ): Result;
}

export interface IRocketDepositPool extends BaseContract {
  connect(runner?: ContractRunner | null): IRocketDepositPool;
  waitForDeployment(): Promise<this>;

  interface: IRocketDepositPoolInterface;

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

  assignDeposits: TypedContractMethod<[], [void], "nonpayable">;

  deposit: TypedContractMethod<[], [void], "payable">;

  getBalance: TypedContractMethod<[], [bigint], "view">;

  getExcessBalance: TypedContractMethod<[], [bigint], "view">;

  getMaximumDepositAmount: TypedContractMethod<[], [bigint], "view">;

  getNodeBalance: TypedContractMethod<[], [bigint], "view">;

  getUserBalance: TypedContractMethod<[], [bigint], "view">;

  maybeAssignDeposits: TypedContractMethod<[], [boolean], "nonpayable">;

  nodeCreditWithdrawal: TypedContractMethod<
    [_amount: BigNumberish],
    [void],
    "nonpayable"
  >;

  nodeDeposit: TypedContractMethod<
    [_totalAmount: BigNumberish],
    [void],
    "payable"
  >;

  recycleDissolvedDeposit: TypedContractMethod<[], [void], "payable">;

  recycleExcessCollateral: TypedContractMethod<[], [void], "payable">;

  recycleLiquidatedStake: TypedContractMethod<[], [void], "payable">;

  withdrawExcessBalance: TypedContractMethod<
    [_amount: BigNumberish],
    [void],
    "nonpayable"
  >;

  getFunction<T extends ContractMethod = ContractMethod>(
    key: string | FunctionFragment
  ): T;

  getFunction(
    nameOrSignature: "assignDeposits"
  ): TypedContractMethod<[], [void], "nonpayable">;
  getFunction(
    nameOrSignature: "deposit"
  ): TypedContractMethod<[], [void], "payable">;
  getFunction(
    nameOrSignature: "getBalance"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "getExcessBalance"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "getMaximumDepositAmount"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "getNodeBalance"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "getUserBalance"
  ): TypedContractMethod<[], [bigint], "view">;
  getFunction(
    nameOrSignature: "maybeAssignDeposits"
  ): TypedContractMethod<[], [boolean], "nonpayable">;
  getFunction(
    nameOrSignature: "nodeCreditWithdrawal"
  ): TypedContractMethod<[_amount: BigNumberish], [void], "nonpayable">;
  getFunction(
    nameOrSignature: "nodeDeposit"
  ): TypedContractMethod<[_totalAmount: BigNumberish], [void], "payable">;
  getFunction(
    nameOrSignature: "recycleDissolvedDeposit"
  ): TypedContractMethod<[], [void], "payable">;
  getFunction(
    nameOrSignature: "recycleExcessCollateral"
  ): TypedContractMethod<[], [void], "payable">;
  getFunction(
    nameOrSignature: "recycleLiquidatedStake"
  ): TypedContractMethod<[], [void], "payable">;
  getFunction(
    nameOrSignature: "withdrawExcessBalance"
  ): TypedContractMethod<[_amount: BigNumberish], [void], "nonpayable">;

  filters: {};
}
