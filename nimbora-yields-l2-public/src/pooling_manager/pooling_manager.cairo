#[starknet::contract]
mod PoolingManager {
    // Starknet import
    use starknet::{
        ContractAddress, get_caller_address, eth_address::{EthAddress, EthAddressZeroable},
        Zeroable, ClassHash, syscalls::{send_message_to_l1_syscall}
    };
    use core::nullable::{nullable_from_box, match_nullable, FromNullableResult};
    use core::integer::{u128_byte_reverse};

    // OZ import
    use openzeppelin::access::accesscontrol::{
        AccessControlComponent, interface::{IAccessControlDispatcher, IAccessControlDispatcherTrait}
    };
    use openzeppelin::token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::upgrades::UpgradeableComponent;

    // Local import
    use nimbora_yields::pooling_manager::interface::{
        IPoolingManager, StrategyReportL1, BridgeInteractionInfo
    };
    use nimbora_yields::token_manager::interface::{
        ITokenManagerDispatcher, ITokenManagerDispatcherTrait, StrategyReportL2
    };
    use nimbora_yields::token_bridge::interface::{
        ITokenBridgeDispatcher, ITokenBridgeDispatcherTrait
    };

    // Components
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    impl InternalUpgradeableImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        factory: ContractAddress,
        fees_recipient: ContractAddress,
        l1_pooling_manager: EthAddress,
        underlying_to_bridge: LegacyMap<ContractAddress, ContractAddress>,
        l2_bridge_to_l1_bridge: LegacyMap<ContractAddress, felt252>,
        l1_strategy_to_token_manager: LegacyMap<EthAddress, ContractAddress>,
        l1_report_hash: LegacyMap<u256, u256>,
        pending_strategies_to_initialize: LegacyMap<u256, EthAddress>,
        pending_strategies_to_initialize_len: u256,
        general_epoch: u256
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        FactoryUpdated: FactoryUpdated,
        FeesRecipientUpdated: FeesRecipientUpdated,
        StrategyRegistered: StrategyRegistered,
        UnderlyingRegistered: UnderlyingRegistered,
        DepositLimitUpdated: DepositLimitUpdated,
        WithdrawalLimitUpdated: WithdrawalLimitUpdated,
        PerformanceFeesUpdated: PerformanceFeesUpdated,
        WithdrawalEpochUpdated: WithdrawalEpochUpdated,
        DustLimitUpdated: DustLimitUpdated,
        Deposit: Deposit,
        RequestWithdrawal: RequestWithdrawal,
        ClaimWithdrawal: ClaimWithdrawal,
        TokenManagerClassHashUpdated: TokenManagerClassHashUpdated,
        TokenClassHashUpdated: TokenClassHashUpdated,
        L1PoolingManagerUpdated: L1PoolingManagerUpdated,
        NewL1ReportHash: NewL1ReportHash,
        NewL2Report: NewL2Report
    }

    #[derive(Drop, starknet::Event)]
    struct FactoryUpdated {
        new_factory: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct FeesRecipientUpdated {
        new_fees_recipient: ContractAddress
    }

    #[derive(Drop, starknet::Event)]
    struct L1PoolingManagerUpdated {
        new_l1_pooling_manager: EthAddress
    }

    #[derive(Drop, starknet::Event)]
    struct NewL1ReportHash {
        new_l1_report_hash: u256
    }

    #[derive(Drop, starknet::Event)]
    struct NewL2Report {
        new_epoch: u256,
        new_bridge_deposit: Array<BridgeInteractionInfo>,
        new_l2_report: Array<StrategyReportL2>,
        new_bridge_withdraw: Array<BridgeInteractionInfo>
    }


    #[derive(Drop, starknet::Event)]
    struct StrategyRegistered {
        token_manager: ContractAddress,
        token: ContractAddress,
        l1_strategy: EthAddress,
        underlying: ContractAddress,
        performance_fees: u256,
        min_deposit: u256,
        max_deposit: u256,
        min_withdrawal: u256,
        max_withdrawal: u256
    }


    #[derive(Drop, starknet::Event)]
    struct UnderlyingRegistered {
        underlying: ContractAddress,
        bridge: ContractAddress,
        l1_bridge: felt252
    }


    #[derive(Drop, starknet::Event)]
    struct DepositLimitUpdated {
        l1_strategy: EthAddress,
        new_min_deposit_limit: u256,
        new_max_deposit_limit: u256
    }


    #[derive(Drop, starknet::Event)]
    struct WithdrawalLimitUpdated {
        l1_strategy: EthAddress,
        new_min_withdrawal_limit: u256,
        new_max_withdrawal_limit: u256
    }


    #[derive(Drop, starknet::Event)]
    struct PerformanceFeesUpdated {
        l1_strategy: EthAddress,
        new_performance_fees: u256
    }

    #[derive(Drop, starknet::Event)]
    struct WithdrawalEpochUpdated {
        l1_strategy: EthAddress,
        new_withdrawal_epoch_delay: u256
    }

    #[derive(Drop, starknet::Event)]
    struct DustLimitUpdated {
        l1_strategy: EthAddress,
        new_dust_limit: u256
    }


    #[derive(Drop, starknet::Event)]
    struct Deposit {
        l1_strategy: EthAddress,
        caller: ContractAddress,
        receiver: ContractAddress,
        assets: u256,
        shares: u256,
        referal: ContractAddress
    }


    #[derive(Drop, starknet::Event)]
    struct RequestWithdrawal {
        l1_strategy: EthAddress,
        caller: ContractAddress,
        assets: u256,
        shares: u256,
        id: u256,
        epoch: u256
    }

    #[derive(Drop, starknet::Event)]
    struct ClaimWithdrawal {
        l1_strategy: EthAddress,
        caller: ContractAddress,
        id: u256,
        underlying_amount: u256
    }

    #[derive(Drop, starknet::Event)]
    struct TokenManagerClassHashUpdated {
        new_token_manager_class_hash: ClassHash
    }

    #[derive(Drop, starknet::Event)]
    struct TokenClassHashUpdated {
        new_token_class_hash: ClassHash
    }


    mod Errors {
        const ZERO_ADDRESS: felt252 = 'Zero address';
        const INVALID_CALLER: felt252 = 'Invalid caller';
        const NOT_SUPPORTED: felt252 = 'Token not supported';
        const ALREADY_REGISTERED: felt252 = 'Strategy already registered';
        const PENDING_HASH: felt252 = 'Pending hash';
        const NO_L1_REPORT: felt252 = 'No l1 report';
        const INVALID_DATA: felt252 = 'Invalid data';
        const EMPTY_ARRAY: felt252 = 'Empty array';
        const UNKNOWN_STRATEGY: felt252 = 'Unknown strategy';
        const TOTAL_ASSETS_NUL: felt252 = 'Total assets nul';
        const NOT_INITIALISED: felt252 = 'Not initialised';
        const BUFFER_NUL: felt252 = 'Buffer is nul';
        const INVALID_EPOCH: felt252 = 'Invalid Epoch';
    }

    /// @notice Constructor for initializing the contract
    /// @param owner The address of the contract owner
    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.accesscontrol.initializer();
        self.accesscontrol._grant_role(0, owner);
    }

    /// @notice Upgrade contract
    /// @param New contract class hash
    #[external(v0)]
    fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
        self.accesscontrol.assert_only_role(0);
        self.upgradeable._upgrade(new_class_hash);
    }


    #[external(v0)]
    fn get_pending_strategies_len(self: @ContractState) -> u256 {
        self.pending_strategies_to_initialize_len.read()
    }

    #[external(v0)]
    fn set_pending_strategies_len(ref self: ContractState, len: u256) {
        self.accesscontrol.assert_only_role(0);
        self.pending_strategies_to_initialize_len.write(len);
    }

    fn reverse_endianness(value: u256) -> u256 {
        let new_low = u128_byte_reverse(value.high);
        let new_high = u128_byte_reverse(value.low);
        u256 { low: new_low, high: new_high }
    }

    /// @notice Handler for incoming messages from L1 contract
    /// @dev This function should only be called by the authorized L1 pooling manager
    /// @param from_address The address of the sender from L1
    /// @param epoch The epoch of the report from L1
    /// @param hash The hash of the report from L1
    #[l1_handler]
    fn handle_response(ref self: ContractState, from_address: felt252, epoch: u256, hash: u256) {
        let l1_pooling_manager = self.l1_pooling_manager.read();
        assert(l1_pooling_manager.into() == from_address, Errors::INVALID_CALLER);
        let general_epoch = self.general_epoch.read();
        assert(general_epoch == epoch, Errors::INVALID_EPOCH);
        let l1_report_hash = self.l1_report_hash.read(general_epoch);
        assert(l1_report_hash.is_zero(), Errors::PENDING_HASH);
        self.l1_report_hash.write(general_epoch, hash);
        self.emit(NewL1ReportHash { new_l1_report_hash: hash })
    }


    #[abi(embed_v0)]
    impl PoolingManager of IPoolingManager<ContractState> {
        /// @notice Returns the factory address
        /// @return The address of the factory
        fn factory(self: @ContractState) -> ContractAddress {
            self.factory.read()
        }

        /// @notice Returns the fees recipient address
        /// @return The address of the fees recipient
        fn fees_recipient(self: @ContractState) -> ContractAddress {
            self.fees_recipient.read()
        }

        /// @notice Returns the L1 pooling manager address
        /// @return The address of the L1 pooling manager
        fn l1_pooling_manager(self: @ContractState) -> EthAddress {
            self.l1_pooling_manager.read()
        }

        /// @notice Checks if the contract is initialised
        /// @return True if the contract is initialised, false otherwise
        fn is_initialised(self: @ContractState) -> bool {
            self._is_initialised()
        }

        /// @notice Maps L1 strategy to token manager
        /// @param l1_strategy The L1 strategy address
        /// @return The corresponding token manager address
        fn l1_strategy_to_token_manager(
            self: @ContractState, l1_strategy: EthAddress
        ) -> ContractAddress {
            self.l1_strategy_to_token_manager.read(l1_strategy)
        }

        /// @notice Maps the underlying asset to its corresponding bridge
        /// @param underlying The address of the underlying asset
        /// @return The address of the corresponding bridge
        fn underlying_to_bridge(
            self: @ContractState, underlying: ContractAddress
        ) -> ContractAddress {
            self.underlying_to_bridge.read(underlying)
        }

        /// @notice Maps the l2 bridge to the l1 corresponding bridge
        /// @param bridge The address of the l2 bridge
        /// @return The address of the corresponding l1 bridge
        fn l2_bridge_to_l1_bridge(self: @ContractState, bridge: ContractAddress) -> felt252 {
            self.l2_bridge_to_l1_bridge.read(bridge)
        }

        /// @notice Reads the L1 report hash for a given epoch
        /// @param general_epoch The epoch for which to retrieve the hash
        /// @return The L1 report hash for the specified epoch
        fn l1_report_hash(self: @ContractState, general_epoch: u256) -> u256 {
            self.l1_report_hash.read(general_epoch)
        }

        /// @notice Generates a hash from L1 data
        /// @param calldata The data to be hashed
        /// @return The hash of the provided L1 data
        fn hash_l1_data(self: @ContractState, calldata: Span<StrategyReportL1>) -> u256 {
            self._hash_l1_data(calldata)
        }

        /// @notice Generates a hash from L2 data
        /// @param new_epoch of pooling manager
        /// @param bridge_deposit_info Span of StrategyReportL2 data
        /// @param strategy_report_l2 Span of StrategyReportL2 data
        /// @param bridge_withdrawal_info Span of StrategyReportL2 data
        /// @return Hash of the L2 data
        fn hash_l2_data(
            self: @ContractState,
            new_epoch: u256,
            bridge_deposit_info: Span<BridgeInteractionInfo>,
            strategy_report_l2: Span<StrategyReportL2>,
            bridge_withdrawal_info: Span<BridgeInteractionInfo>
        ) -> u256 {
            self
                ._hash_l2_data(
                    new_epoch, bridge_deposit_info, strategy_report_l2, bridge_withdrawal_info
                )
        }

        /// @notice Reads the general epoch
        /// @return The general epoch
        fn general_epoch(self: @ContractState) -> u256 {
            self.general_epoch.read()
        }

        /// @notice Retrieves the list of pending strategies to be initialized
        /// @return Array of Ethereum addresses representing the pending strategies
        fn pending_strategies_to_initialize(self: @ContractState) -> Array<EthAddress> {
            self._pending_strategies_to_initialize()
        }

        /// @notice Sets the fees recipient address
        /// @dev This function can only be called by an account with the appropriate role
        /// @param new_fees_recipient The new address to receive fees
        fn set_fees_recipient(ref self: ContractState, new_fees_recipient: ContractAddress) {
            self.accesscontrol.assert_only_role(0);
            assert(new_fees_recipient.is_non_zero(), Errors::ZERO_ADDRESS);
            self.fees_recipient.write(new_fees_recipient);
            self.emit(FeesRecipientUpdated { new_fees_recipient: new_fees_recipient });
        }

        /// @notice Updates the L1 pooling manager address
        /// @dev This function can only be called by an account with the appropriate role
        /// @param new_l1_pooling_manager The new L1 pooling manager address
        fn set_l1_pooling_manager(ref self: ContractState, new_l1_pooling_manager: EthAddress) {
            self.accesscontrol.assert_only_role(0);
            assert(new_l1_pooling_manager.is_non_zero(), Errors::ZERO_ADDRESS);
            self.l1_pooling_manager.write(new_l1_pooling_manager);
            self.emit(L1PoolingManagerUpdated { new_l1_pooling_manager: new_l1_pooling_manager });
        }

        /// @notice Sets a new factory address
        /// @dev This function can only be called by an account with the appropriate role
        /// @param new_factory The new factory address
        fn set_factory(ref self: ContractState, new_factory: ContractAddress) {
            self.accesscontrol.assert_only_role(0);
            assert(new_factory.is_non_zero(), Errors::ZERO_ADDRESS);
            self.factory.write(new_factory);
            self.emit(FactoryUpdated { new_factory: new_factory });
        }

        /// @notice Allowance for 
        /// @dev This function can only be called by an account with the appropriate role
        /// @param new_l1_pooling_manager The new L1 pooling manager address
        fn set_allowance(
            ref self: ContractState,
            spender: ContractAddress,
            token_address: ContractAddress,
            amount: u256
        ) {
            self.accesscontrol.assert_only_role(0);
            assert(spender.is_non_zero() && token_address.is_non_zero(), Errors::ZERO_ADDRESS);
            let underlying_disp = ERC20ABIDispatcher { contract_address: token_address };
            underlying_disp.approve(spender, amount);
        }

        /// @notice Registers a new strategy within the contract
        /// @dev This function can only be called by the factory
        /// @param token_manager_deployed_address The deployed address of the token manager associated with the strategy
        /// @param token_deployed_address The deployed address of the token associated with the strategy
        /// @param l1_strategy The Ethereum address of the L1 strategy
        /// @param underlying The contract address of the underlying asset for the strategy
        /// @param performance_fees The performance fee (as a percentage) associated with the strategy
        /// @param min_deposit The minimum deposit amount allowed for the strategy
        /// @param max_deposit The maximum deposit amount allowed for the strategy
        /// @param min_withdrawal The minimum withdrawal amount allowed for the strategy
        /// @param max_withdrawal The maximum withdrawal amount allowed for the strategy
        /// @desc This function initializes a new strategy by setting up the token manager, registering the strategy with its L1 counterpart, 
        /// and defining the key parameters like deposit/withdrawal limits and fees. It also adds the strategy to a list of pending strategies to be initialized.
        fn register_strategy(
            ref self: ContractState,
            token_manager_deployed_address: ContractAddress,
            token_deployed_address: ContractAddress,
            l1_strategy: EthAddress,
            underlying: ContractAddress,
            performance_fees: u256,
            min_deposit: u256,
            max_deposit: u256,
            min_withdrawal: u256,
            max_withdrawal: u256
        ) {
            self._assert_caller_is_factory();
            let bridge = self.underlying_to_bridge.read(underlying);
            assert(bridge.is_non_zero(), Errors::NOT_SUPPORTED);
            let token_manager_disp = ITokenManagerDispatcher {
                contract_address: token_manager_deployed_address
            };
            token_manager_disp.initialiser(token_deployed_address);
            let current_l1_strategy_to_token_manager = self
                .l1_strategy_to_token_manager
                .read(l1_strategy);
            assert(current_l1_strategy_to_token_manager.is_zero(), Errors::ALREADY_REGISTERED);
            self.l1_strategy_to_token_manager.write(l1_strategy, token_manager_deployed_address);

            let pending_strategies_to_initialize_len = self
                .pending_strategies_to_initialize_len
                .read();
            self
                .pending_strategies_to_initialize
                .write(pending_strategies_to_initialize_len, l1_strategy);
            self
                .pending_strategies_to_initialize_len
                .write(pending_strategies_to_initialize_len + 1);
            self
                .emit(
                    StrategyRegistered {
                        token_manager: token_manager_deployed_address,
                        token: token_deployed_address,
                        l1_strategy: l1_strategy,
                        underlying: underlying,
                        performance_fees: performance_fees,
                        min_deposit: min_deposit,
                        max_deposit: max_deposit,
                        min_withdrawal: min_withdrawal,
                        max_withdrawal: max_withdrawal
                    }
                );
        }

        /// @notice Registers an underlying asset and its corresponding bridge contract
        /// @dev This function can only be called by an account with the appropriate role (typically admin)
        /// @param underlying The contract address of the underlying asset to be registered
        /// @param bridge The contract address of the bridge associated with the underlying asset
        /// @desc This function is used to link an underlying asset with its corresponding bridge contract in the system. 
        ///        It ensures that the underlying asset can be bridged properly and is a critical part of setting up the contract's infrastructure. 
        ///        The function also emits an event upon successful registration.
        fn register_underlying(
            ref self: ContractState,
            underlying: ContractAddress,
            bridge: ContractAddress,
            l1_bridge: felt252
        ) {
            self.accesscontrol.assert_only_role(0);
            assert(
                underlying.is_non_zero() && bridge.is_non_zero() && l1_bridge.is_non_zero(),
                Errors::ZERO_ADDRESS
            );
            let bridge_disp = ITokenBridgeDispatcher { contract_address: bridge };
            self.underlying_to_bridge.write(underlying, bridge);
            // let l1_bridge = bridge_disp.get_l1_bridge();
            self.l2_bridge_to_l1_bridge.write(bridge, l1_bridge);
            self
                .emit(
                    UnderlyingRegistered {
                        underlying: underlying, bridge: bridge, l1_bridge: l1_bridge
                    }
                );
        }

        /// @notice Handles a mass report of L1 strategy data, processing and updating L2 state accordingly
        /// @dev This function processes reports from L1, verifies data integrity, and performs necessary transfers and updates
        /// @param calldata The span of StrategyReportL1 data received from L1
        /// @desc This function is crucial for synchronizing L1 strategy data with the L2 contract's state.
        ///       It reads the general epoch and corresponding L1 report hash, verifies the received data against the expected hash,
        ///       and processes each report element. For each report, it handles asset transfers, updates strategy data,
        ///       and accumulates bridge amounts for withdrawal initiation.
        ///       After processing all elements, it initiates withdrawals to L1 and emits an event with the new L2 report data.
        ///       The function ensures that only valid and expected data is processed and that the contract's state remains consistent with L1.
        fn handle_mass_report(ref self: ContractState, calldata: Span<StrategyReportL1>) {
            let general_epoch = self.general_epoch.read();
            let l1_report_hash = self.l1_report_hash.read(general_epoch);

            if (general_epoch.is_non_zero()) {
                assert(l1_report_hash.is_non_zero(), Errors::NO_L1_REPORT);
                let calldata_hash = self._hash_l1_data(calldata);
                assert(calldata_hash == l1_report_hash, Errors::INVALID_DATA);
            } else {
                assert(calldata.len() == 0, Errors::INVALID_DATA);
                let is_initialised = self._is_initialised();
                assert(is_initialised, Errors::NOT_INITIALISED);
            }

            let full_strategy_report_l1 = self._add_pending_strategies_to_initialize(calldata);

            let array_len = full_strategy_report_l1.len();
            assert(array_len.is_non_zero(), Errors::EMPTY_ARRAY);

            let mut strategy_report_l2_array = ArrayTrait::new();

            let mut dict_bridge_deposit_keys = ArrayTrait::new();
            let mut bridge_deposit_amount: Felt252Dict<Nullable<u256>> = Default::default();

            let mut dict_bridge_withdrawal_keys = ArrayTrait::new();
            let mut bridge_withdrawal_amount: Felt252Dict<Nullable<u256>> = Default::default();

            let mut i = 0;
            loop {
                if (i == array_len) {
                    break ();
                }
                let elem = *full_strategy_report_l1.at(i);
                let strategy = self.l1_strategy_to_token_manager.read(elem.l1_strategy);
                let strategy_disp = ITokenManagerDispatcher { contract_address: strategy };
                let underlying = strategy_disp.underlying();
                let underlying_disp = ERC20ABIDispatcher { contract_address: underlying };
                if (elem.underlying_bridged_amount.is_non_zero()) {
                    underlying_disp.transfer(strategy, elem.underlying_bridged_amount);
                }
                let ret = strategy_disp
                    .handle_report(elem.l1_net_asset_value, elem.underlying_bridged_amount);
                strategy_report_l2_array.append(ret);

                if (ret.action_id == 0) {
                    let bridge = self.underlying_to_bridge.read(underlying);
                    let val = bridge_deposit_amount.get(bridge.into());
                    let current_bridge_deposit_amount: u256 = match match_nullable(val) {
                        FromNullableResult::Null => 0,
                        FromNullableResult::NotNull(val) => val.unbox(),
                    };
                    if (current_bridge_deposit_amount.is_zero()) {
                        let new_amount = nullable_from_box(BoxTrait::new(ret.amount));
                        dict_bridge_deposit_keys.append(bridge);
                        bridge_deposit_amount.insert(bridge.into(), new_amount);
                    } else {
                        let new_amount = nullable_from_box(
                            BoxTrait::new(ret.amount + current_bridge_deposit_amount)
                        );
                        bridge_deposit_amount.insert(bridge.into(), new_amount);
                    }
                }

                if (ret.action_id == 2) {
                    let bridge = self.underlying_to_bridge.read(underlying);
                    let val = bridge_withdrawal_amount.get(bridge.into());
                    let current_bridge_withdrawal_amount: u256 = match match_nullable(val) {
                        FromNullableResult::Null => 0,
                        FromNullableResult::NotNull(val) => val.unbox(),
                    };
                    if (current_bridge_withdrawal_amount.is_zero()) {
                        let new_amount = nullable_from_box(BoxTrait::new(ret.amount));
                        dict_bridge_withdrawal_keys.append(bridge);
                        bridge_withdrawal_amount.insert(bridge.into(), new_amount);
                    } else {
                        let new_amount = nullable_from_box(
                            BoxTrait::new(ret.amount + current_bridge_withdrawal_amount)
                        );
                        bridge_withdrawal_amount.insert(bridge.into(), new_amount);
                    }
                }
                i += 1;
            };

            let l1_pooling_manager = self.l1_pooling_manager.read();

            let mut bridge_deposit_info = ArrayTrait::new();
            let mut j = 0;
            let dict_bridge_deposit_keys_len = dict_bridge_deposit_keys.len();
            loop {
                if (j == dict_bridge_deposit_keys_len) {
                    break ();
                }
                let bridge_address = *dict_bridge_deposit_keys.at(j);
                let val = bridge_deposit_amount.get(bridge_address.into());
                let amount: u256 = match match_nullable(val) {
                    FromNullableResult::Null => 0,
                    FromNullableResult::NotNull(val) => val.unbox(),
                };
                let bridge_disp = ITokenBridgeDispatcher { contract_address: bridge_address };
                bridge_disp.initiate_withdraw(l1_pooling_manager.into(), amount);

                let l1_bridge = self.l2_bridge_to_l1_bridge.read(bridge_address);
                bridge_deposit_info
                    .append(BridgeInteractionInfo { l1_bridge: l1_bridge, amount: amount });
                j += 1;
            };

            let mut bridge_withdrawal_info = ArrayTrait::new();
            j = 0;
            let dict_bridge_withdrawal_keys_len = dict_bridge_withdrawal_keys.len();
            loop {
                if (j == dict_bridge_withdrawal_keys_len) {
                    break ();
                }
                let bridge_address = *dict_bridge_withdrawal_keys.at(j);
                let val = bridge_withdrawal_amount.get(bridge_address.into());
                let amount: u256 = match match_nullable(val) {
                    FromNullableResult::Null => 0,
                    FromNullableResult::NotNull(val) => val.unbox(),
                };

                let l1_bridge = self.l2_bridge_to_l1_bridge.read(bridge_address);
                bridge_withdrawal_info
                    .append(BridgeInteractionInfo { l1_bridge: l1_bridge, amount: amount });
                j += 1;
            };

            let new_epoch = general_epoch + 1;
            self.general_epoch.write(new_epoch);

            let ret_hash = self
                ._hash_l2_data(
                    new_epoch,
                    bridge_deposit_info.span(),
                    strategy_report_l2_array.span(),
                    bridge_withdrawal_info.span()
                );
            let mut message_payload: Array<felt252> = ArrayTrait::new();
            message_payload.append(ret_hash.low.into());
            message_payload.append(ret_hash.high.into());
            send_message_to_l1_syscall(
                to_address: l1_pooling_manager.into(), payload: message_payload.span()
            );
            self
                .emit(
                    NewL2Report {
                        new_epoch: new_epoch,
                        new_bridge_deposit: bridge_deposit_info,
                        new_l2_report: strategy_report_l2_array,
                        new_bridge_withdraw: bridge_withdrawal_info
                    }
                );
        }

        fn delete_all_pending_strategy(ref self: ContractState) {
            self.accesscontrol.assert_only_role(0);
            let mut i = 0;
            let pending_strategies_to_initialize_len = self
                .pending_strategies_to_initialize_len
                .read();
            loop {
                if (i == pending_strategies_to_initialize_len) {
                    break ();
                }
                self.pending_strategies_to_initialize.write(i, EthAddressZeroable::zero());
                i += 1;
            };
            self.pending_strategies_to_initialize_len.write(0);
        }


        /// @notice Emits an event when deposit limits are updated for a strategy
        /// @dev Only callable by a registered token manager
        /// @param l1_strategy The Ethereum address of the L1 strategy for which limits are updated
        /// @param new_min_deposit_limit The updated minimum deposit limit
        /// @param new_max_deposit_limit The updated maximum deposit limit
        fn emit_deposit_limit_updated_event(
            ref self: ContractState,
            l1_strategy: EthAddress,
            new_min_deposit_limit: u256,
            new_max_deposit_limit: u256
        ) {
            self._assert_caller_is_registered_token_manager(l1_strategy);
            self
                .emit(
                    DepositLimitUpdated {
                        l1_strategy: l1_strategy,
                        new_min_deposit_limit: new_min_deposit_limit,
                        new_max_deposit_limit: new_max_deposit_limit
                    }
                );
        }

        /// @notice Emits an event when withdrawal limits are updated for a strategy
        /// @dev Only callable by a registered token manager
        /// @param l1_strategy The Ethereum address of the L1 strategy for which limits are updated
        /// @param new_min_withdrawal_limit The updated minimum withdrawal limit
        /// @param new_max_withdrawal_limit The updated maximum withdrawal limit
        fn emit_withdrawal_limit_updated_event(
            ref self: ContractState,
            l1_strategy: EthAddress,
            new_min_withdrawal_limit: u256,
            new_max_withdrawal_limit: u256
        ) {
            self._assert_caller_is_registered_token_manager(l1_strategy);
            self
                .emit(
                    WithdrawalLimitUpdated {
                        l1_strategy: l1_strategy,
                        new_min_withdrawal_limit: new_min_withdrawal_limit,
                        new_max_withdrawal_limit: new_max_withdrawal_limit
                    }
                );
        }

        /// @notice Emits an event when performance fees are updated for a strategy
        /// @dev Only callable by a registered token manager
        /// @param l1_strategy The Ethereum address of the L1 strategy
        /// @param new_performance_fees The updated performance fees
        fn emit_performance_fees_updated_event(
            ref self: ContractState, l1_strategy: EthAddress, new_performance_fees: u256
        ) {
            self._assert_caller_is_registered_token_manager(l1_strategy);
            self
                .emit(
                    PerformanceFeesUpdated {
                        l1_strategy: l1_strategy, new_performance_fees: new_performance_fees
                    }
                );
        }


        /// @notice Emits a deposit event for a strategy
        /// @dev Only callable by a registered token manager
        /// @param l1_strategy The Ethereum address of the L1 strategy
        /// @param caller The address of the caller
        /// @param receiver The address of the receiver
        /// @param assets The amount of assets deposited
        /// @param shares The amount of shares received
        /// @param referal The address of the referal
        fn emit_deposit_event(
            ref self: ContractState,
            l1_strategy: EthAddress,
            caller: ContractAddress,
            receiver: ContractAddress,
            assets: u256,
            shares: u256,
            referal: ContractAddress
        ) {
            self._assert_caller_is_registered_token_manager(l1_strategy);
            self
                .emit(
                    Deposit {
                        l1_strategy: l1_strategy,
                        caller: caller,
                        receiver: receiver,
                        assets: assets,
                        shares: shares,
                        referal: referal
                    }
                );
        }

        /// @notice Emits an event for a withdrawal request
        /// @dev Only callable by a registered token manager
        /// @param l1_strategy The Ethereum address of the L1 strategy
        /// @param caller The address of the caller
        /// @param assets The amount of assets requested for withdrawal
        /// @param shares The amount of shares to be redeemed
        /// @param id The unique identifier of the withdrawal for a user
        /// @param epoch The epoch during which the request was made
        fn emit_request_withdrawal_event(
            ref self: ContractState,
            l1_strategy: EthAddress,
            caller: ContractAddress,
            assets: u256,
            shares: u256,
            id: u256,
            epoch: u256
        ) {
            self._assert_caller_is_registered_token_manager(l1_strategy);
            self
                .emit(
                    RequestWithdrawal {
                        l1_strategy: l1_strategy,
                        caller: caller,
                        assets: assets,
                        shares: shares,
                        id: id,
                        epoch: epoch
                    }
                );
        }

        /// @notice Emits an event when a withdrawal is claimed
        /// @dev Only callable by a registered token manager
        /// @param l1_strategy The Ethereum address of the L1 strategy
        /// @param caller The address of the caller
        /// @param id The unique identifier of the withdrawal for a user
        /// @param underlying_amount The amount of underlying asset withdrawn
        fn emit_claim_withdrawal_event(
            ref self: ContractState,
            l1_strategy: EthAddress,
            caller: ContractAddress,
            id: u256,
            underlying_amount: u256
        ) {
            self._assert_caller_is_registered_token_manager(l1_strategy);
            self
                .emit(
                    ClaimWithdrawal {
                        l1_strategy: l1_strategy,
                        caller: caller,
                        id: id,
                        underlying_amount: underlying_amount
                    }
                );
        }

        /// @notice Emits an event when the withdrawal epoch delay is updated for a strategy
        /// @dev Only callable by a registered token manager
        /// @param l1_strategy The Ethereum address of the L1 strategy
        /// @param new_withdrawal_epoch_delay The updated withdrawal epoch delay
        fn emit_withdrawal_epoch_delay_updated_event(
            ref self: ContractState, l1_strategy: EthAddress, new_withdrawal_epoch_delay: u256
        ) {
            self._assert_caller_is_registered_token_manager(l1_strategy);
            self
                .emit(
                    WithdrawalEpochUpdated {
                        l1_strategy: l1_strategy,
                        new_withdrawal_epoch_delay: new_withdrawal_epoch_delay
                    }
                );
        }


        /// @notice Emits an event when the dust limit is updated for a strategy
        /// @dev Only callable by a registered token manager
        /// @param l1_strategy The Ethereum address of the L1 strategy
        /// @param new_dust_limit The updated dust limit
        fn emit_dust_limit_updated_event(
            ref self: ContractState, l1_strategy: EthAddress, new_dust_limit: u256
        ) {
            self._assert_caller_is_registered_token_manager(l1_strategy);
            self
                .emit(
                    DustLimitUpdated { l1_strategy: l1_strategy, new_dust_limit: new_dust_limit }
                );
        }

        /// @notice Emits an event when the token manager class hash is updated
        /// @dev Only callable by the factory
        /// @param new_token_manager_class_hash The updated class hash for the token manager
        fn emit_token_manager_class_hash_updated_event(
            ref self: ContractState, new_token_manager_class_hash: ClassHash
        ) {
            self._assert_caller_is_factory();
            self
                .emit(
                    TokenManagerClassHashUpdated {
                        new_token_manager_class_hash: new_token_manager_class_hash
                    }
                );
        }

        /// @notice Emits an event when the token class hash is updated
        /// @dev Only callable by the factory
        /// @param new_token_class_hash The updated class hash for the token
        fn emit_token_class_hash_updated_event(
            ref self: ContractState, new_token_class_hash: ClassHash
        ) {
            self._assert_caller_is_factory();
            self.emit(TokenClassHashUpdated { new_token_class_hash: new_token_class_hash });
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// @notice Asserts that the caller is a registered token manager for the given L1 strategy
        /// @dev Verifies if the caller address matches the registered token manager for the specified L1 strategy
        /// @param l1_strategy The Ethereum address of the L1 strategy
        fn _assert_caller_is_registered_token_manager(
            self: @ContractState, l1_strategy: EthAddress
        ) {
            let caller = get_caller_address();
            let token_manager = self.l1_strategy_to_token_manager.read(l1_strategy);
            assert(token_manager == caller, Errors::INVALID_CALLER);
        }

        /// @notice Asserts that the caller is the factory
        /// @dev Verifies if the caller address matches the registered factory address
        fn _assert_caller_is_factory(self: @ContractState) {
            let caller_address = get_caller_address();
            let factory = self.factory.read();
            assert(caller_address == factory, Errors::INVALID_CALLER);
        }

        /// @notice Checks if the contract is initialized
        /// @return True if the contract is initialized, otherwise false
        /// @dev Initialization is determined based on whether key contract addresses are non-zero
        fn _is_initialised(self: @ContractState) -> bool {
            let l1_pooling_manager = self.l1_pooling_manager.read();
            let fees_recipient = self.fees_recipient.read();
            let factory = self.factory.read();
            if (l1_pooling_manager.is_zero() || fees_recipient.is_zero() || factory.is_zero()) {
                false
            } else {
                true
            }
        }

        /// @notice Converts a span of L1 strategy reports to a span of u256
        /// @param calldata Span of StrategyReportL1 data
        /// @return Span of u256 values representing the L1 strategy reports
        fn _strategy_report_l1_to_u256_span(
            self: @ContractState, calldata: Span<StrategyReportL1>
        ) -> Span<u256> {
            let mut ret_array = ArrayTrait::new();
            let array_len = calldata.len();
            let mut i = 0;
            loop {
                if (i == array_len) {
                    break ();
                }
                let elem = *calldata.at(i);
                let l1_strategy_felt: felt252 = elem.l1_strategy.into();
                let l1_strategy_u256: u256 = l1_strategy_felt.into();
                ret_array.append(l1_strategy_u256);
                ret_array.append(elem.l1_net_asset_value);
                ret_array.append(elem.underlying_bridged_amount);
                i += 1;
            };
            ret_array.span()
        }

        /// @notice Converts a span of L2 strategy reports to a span of u256
        /// @param new_epoch of pooling manager
        /// @param bridge_deposit_info Span of StrategyReportL2 data
        /// @param strategy_report_l2 Span of StrategyReportL2 data
        /// @param bridge_withdrawal_info Span of StrategyReportL2 data
        /// @return Span of u256 values representing the L2 strategy reports
        fn _strategy_report_l2_to_u256_span(
            self: @ContractState,
            new_epoch: u256,
            bridge_deposit_info: Span<BridgeInteractionInfo>,
            strategy_report_l2: Span<StrategyReportL2>,
            bridge_withdrawal_info: Span<BridgeInteractionInfo>
        ) -> Span<u256> {
            let mut ret_array = ArrayTrait::new();
            ret_array.append(new_epoch);
            let mut array_len = bridge_deposit_info.len();
            let mut i = 0;
            loop {
                if (i == array_len) {
                    break ();
                }
                let bridge_deposit_info_elem = *bridge_deposit_info.at(i);
                let l1_bridge_u256: u256 = bridge_deposit_info_elem.l1_bridge.into();
                ret_array.append(l1_bridge_u256);
                ret_array.append(bridge_deposit_info_elem.amount);
                i += 1;
            };

            array_len = strategy_report_l2.len();
            i = 0;
            loop {
                if (i == array_len) {
                    break ();
                }
                let strategy_report_l2_elem = *strategy_report_l2.at(i);
                let l1_strategy_felt: felt252 = strategy_report_l2_elem.l1_strategy.into();
                let l1_strategy_u256: u256 = l1_strategy_felt.into();
                ret_array.append(l1_strategy_u256);
                ret_array.append(strategy_report_l2_elem.action_id);
                ret_array.append(strategy_report_l2_elem.amount);
                i += 1;
            };

            array_len = bridge_withdrawal_info.len();
            i = 0;
            loop {
                if (i == array_len) {
                    break ();
                }
                let bridge_withdrawal_info_elem = *bridge_withdrawal_info.at(i);
                let l1_bridge_u256: u256 = bridge_withdrawal_info_elem.l1_bridge.into();
                ret_array.append(l1_bridge_u256);
                ret_array.append(bridge_withdrawal_info_elem.amount);
                i += 1;
            };
            ret_array.span()
        }

        /// @notice Generates a hash from L1 data
        /// @param calldata Span of StrategyReportL1 data
        /// @return Hash of the L1 data
        fn _hash_l1_data(self: @ContractState, calldata: Span<StrategyReportL1>) -> u256 {
            let u256_span = self._strategy_report_l1_to_u256_span(calldata);
            let hash = keccak::keccak_u256s_be_inputs(u256_span);
            reverse_endianness(hash)
        }

        /// @notice Generates a hash from L2 data
        /// @param new_epoch of pooling manager
        /// @param bridge_deposit_info Span of StrategyReportL2 data
        /// @param strategy_report_l2 Span of StrategyReportL2 data
        /// @param bridge_withdrawal_info Span of StrategyReportL2 data
        /// @return Hash of the L2 data
        fn _hash_l2_data(
            self: @ContractState,
            new_epoch: u256,
            bridge_deposit_info: Span<BridgeInteractionInfo>,
            strategy_report_l2: Span<StrategyReportL2>,
            bridge_withdrawal_info: Span<BridgeInteractionInfo>
        ) -> u256 {
            let u256_span = self
                ._strategy_report_l2_to_u256_span(
                    new_epoch, bridge_deposit_info, strategy_report_l2, bridge_withdrawal_info
                );
            let hash = keccak::keccak_u256s_be_inputs(u256_span);
            reverse_endianness(hash)
        }

        // @notice Retrieves pending strategies to be initialized
        /// @return Array of Ethereum addresses representing the pending strategies
        fn _pending_strategies_to_initialize(self: @ContractState) -> Array<EthAddress> {
            let mut i = 0;
            let pending_strategies_to_initialize_len = self
                .pending_strategies_to_initialize_len
                .read();
            let mut ret_array = ArrayTrait::new();
            loop {
                if (i == pending_strategies_to_initialize_len) {
                    break ();
                }
                let elem = self.pending_strategies_to_initialize.read(i);
                ret_array.append(elem);
                i += 1;
            };
            ret_array
        }

        // @notice Retrieves pending strategies to be initialized and delete
        /// @return Array of Ethereum addresses representing the pending strategies
        fn _get_pending_strategies_and_del(ref self: ContractState) -> Array<EthAddress> {
            let mut i = 0;
            let pending_strategies_to_initialize_len = self
                .pending_strategies_to_initialize_len
                .read();
            let mut ret_array = ArrayTrait::new();
            loop {
                if (i == pending_strategies_to_initialize_len) {
                    break ();
                }
                let elem = self.pending_strategies_to_initialize.read(i);
                ret_array.append(elem);
                self.pending_strategies_to_initialize.write(i, EthAddressZeroable::zero());
                i += 1;
            };
            self.pending_strategies_to_initialize_len.write(0);

            ret_array
        }

        /// @notice Adds pending strategies to be initialized to the span of StrategyReportL1 data
        /// @param calldata Span of StrategyReportL1 data
        /// @return Span of StrategyReportL1 data including pending strategies
        fn _add_pending_strategies_to_initialize(
            ref self: ContractState, calldata: Span<StrategyReportL1>
        ) -> Span<StrategyReportL1> {
            let mut ret_array = ArrayTrait::new();
            let calldata_len = calldata.len();
            let pending_strategies_to_initialize = self._get_pending_strategies_and_del().span();
            let pending_strategies_to_initialize_len = pending_strategies_to_initialize.len();
            let mut i = 0;
            loop {
                if (i == calldata_len) {
                    break ();
                }
                ret_array.append(*calldata.at(i));
                i += 1;
            };

            i = 0;
            loop {
                if (i == pending_strategies_to_initialize_len) {
                    break ();
                }
                let mut l1_strategy = *pending_strategies_to_initialize.at(i.into());
                let token_manager = self.l1_strategy_to_token_manager.read(l1_strategy);
                let token_manager_disp = ITokenManagerDispatcher {
                    contract_address: token_manager
                };
                let buffer = token_manager_disp.buffer();
                assert(buffer.is_non_zero(), Errors::BUFFER_NUL);
                let new_elem = StrategyReportL1 {
                    l1_strategy: l1_strategy, l1_net_asset_value: 0, underlying_bridged_amount: 0
                };
                ret_array.append(new_elem);
                i += 1;
            };
            ret_array.span()
        }
    }
}
