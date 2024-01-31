#[starknet::contract]
mod MockTokenManager {
    use starknet::{
        ContractAddress, get_caller_address, get_contract_address, eth_address::EthAddress,
        Zeroable, ClassHash
    };


    use openzeppelin::token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use openzeppelin::token::erc721::interface::{ERC721ABIDispatcher, ERC721ABIDispatcherTrait};
    use openzeppelin::access::accesscontrol::interface::{
        IAccessControlDispatcher, IAccessControlDispatcherTrait
    };
    use openzeppelin::upgrades::UpgradeableComponent;


    use nimbora_yields::token_manager::interface::{ITokenManager, WithdrawalInfo, StrategyReportL2};
    use nimbora_yields::token::interface::{ITokenDispatcher, ITokenDispatcherTrait};
    use nimbora_yields::pooling_manager::interface::{
        IPoolingManagerDispatcher, IPoolingManagerDispatcherTrait
    };

    use nimbora_yields::utils::{CONSTANTS, MATH};

    // Components
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    impl InternalUpgradeableImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        pooling_manager: ContractAddress,
        l1_strategy: EthAddress,
        underlying: ContractAddress,
        performance_fees: u256,
        deposit_limit_low: u256,
        deposit_limit_high: u256,
        withdrawal_limit_low: u256,
        withdrawal_limit_high: u256,
        withdrawal_epoch_delay: u256,
        token: ContractAddress,
        epoch: u256,
        l1_net_asset_value: u256,
        underlying_transit: u256,
        buffer: u256,
        handled_epoch_withdrawal_len: u256,
        withdrawal_info: LegacyMap<(ContractAddress, u256), WithdrawalInfo>,
        dust_limit: u256,
        withdrawal_pool: LegacyMap<u256, u256>,
        withdrawal_share: LegacyMap<u256, u256>,
        user_withdrawal_len: LegacyMap<ContractAddress, u256>
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event
    }


    mod Errors {
        const INVALID_CALLER: felt252 = 'Invalid caller';
        const INVALID_FEES: felt252 = 'Fee amount too high';
        const ZERO_AMOUNT: felt252 = 'Amount nul';
        const ZERO_ADDRESS: felt252 = 'Address is zero';
        const INVALID_LIMIT: felt252 = 'Invalid limit';
        const LOW_LIMIT: felt252 = 'Low limit reacher';
        const HIGH_LIMIT: felt252 = 'High limit reacher';
        const NOT_OWNER: felt252 = 'Not owner';
        const WITHDRAWAL_NOT_REDY: felt252 = 'Withdrawal not ready';
        const ALREADY_CLAIMED: felt252 = 'Already claimed';
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        pooling_manager: ContractAddress,
        l1_strategy: EthAddress,
        underlying: ContractAddress,
        performance_fees: u256,
        min_deposit: u256,
        max_deposit: u256,
        min_withdrawal: u256,
        max_withdrawal: u256,
        withdrawal_epoch_delay: u256,
        dust_limit: u256
    ) {
        self.pooling_manager.write(pooling_manager);
        assert(l1_strategy.is_non_zero(), Errors::ZERO_ADDRESS);
        self.l1_strategy.write(l1_strategy);
        self.underlying.write(underlying);
        self._set_performance_fees(performance_fees);
        self._set_deposit_limit(min_deposit, max_deposit);
        self._set_withdrawal_limit(min_withdrawal, max_withdrawal);
        self._set_withdrawal_epoch_delay(withdrawal_epoch_delay);
        self._set_dust_limit(dust_limit);
    }

    /// @notice Upgrade contract
    /// @param New contract class hash
    #[external(v0)]
    fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
        self._assert_only_owner();
        self.upgradeable._upgrade(new_class_hash);
    }

    /// @notice Function to test upgradable
    /// @param None
    #[external(v0)]
    fn get_thousand(self: @ContractState) -> felt252 {
        1000
    }

    #[abi(embed_v0)]
    impl TokenManager of ITokenManager<ContractState> {
        /// @notice Returns the pooling manager address
        /// @return The contract address of the pooling manager
        fn pooling_manager(self: @ContractState) -> ContractAddress {
            self.pooling_manager.read()
        }

        /// @notice Returns the L1 strategy address
        /// @return The Ethereum address of the L1 strategy
        fn l1_strategy(self: @ContractState) -> EthAddress {
            self.l1_strategy.read()
        }

        /// @notice Returns the underlying asset address
        /// @return The contract address of the underlying asset
        fn underlying(self: @ContractState) -> ContractAddress {
            self.underlying.read()
        }

        /// @notice Returns the token address
        /// @return The contract address of the token
        fn token(self: @ContractState) -> ContractAddress {
            self.token.read()
        }

        /// @notice Returns the current performance fees
        /// @return The performance fees as a u256 value
        fn performance_fees(self: @ContractState) -> u256 {
            self.performance_fees.read()
        }

        /// @notice Reads the low deposit limit
        /// @return The current low limit for deposits
        fn deposit_limit_low(self: @ContractState) -> u256 {
            self.deposit_limit_low.read()
        }

        /// @notice Reads the high deposit limit
        /// @return The current high limit for deposits
        fn deposit_limit_high(self: @ContractState) -> u256 {
            self.deposit_limit_high.read()
        }

        /// @notice Reads the low withdrawal limit
        /// @return The current low limit for withdrawals
        fn withdrawal_limit_low(self: @ContractState) -> u256 {
            self.withdrawal_limit_low.read()
        }

        /// @notice Reads the high withdrawal limit
        /// @return The current high limit for withdrawals
        fn withdrawal_limit_high(self: @ContractState) -> u256 {
            self.withdrawal_limit_high.read()
        }

        /// @notice Reads the withdrawal epoch delay
        /// @return The current delay in epochs for withdrawals
        fn withdrawal_epoch_delay(self: @ContractState) -> u256 {
            self.withdrawal_epoch_delay.read()
        }


        /// @notice Reads the current epoch
        /// @return The current epoch value
        fn epoch(self: @ContractState) -> u256 {
            self.epoch.read()
        }

        /// @notice Reads the net asset value from L1
        /// @return The net asset value from L1
        fn l1_net_asset_value(self: @ContractState) -> u256 {
            self.l1_net_asset_value.read()
        }

        /// @notice Reads the underlying asset in transit
        /// @return The amount of underlying asset currently in transit
        fn underlying_transit(self: @ContractState) -> u256 {
            self.underlying_transit.read()
        }

        /// @notice Reads the buffer value
        /// @return The current buffer value
        fn buffer(self: @ContractState) -> u256 {
            self.buffer.read()
        }

        /// @notice Reads the length of handled epoch withdrawals
        /// @return The length of handled epoch withdrawals
        fn handled_epoch_withdrawal_len(self: @ContractState) -> u256 {
            self.handled_epoch_withdrawal_len.read()
        }

        /// @notice Reads withdrawal information for a given user and ID
        /// @param user The address of the user
        /// @param id The unique identifier of the withdrawal
        /// @return Withdrawal information corresponding to the user and ID
        fn withdrawal_info(
            self: @ContractState, user: ContractAddress, id: u256
        ) -> WithdrawalInfo {
            self.withdrawal_info.read((user, id))
        }

        /// @notice Reads the length of withdrawals for a user
        /// @param user The address of the user
        /// @return The number of withdrawals associated with the user
        fn user_withdrawal_len(self: @ContractState, user: ContractAddress) -> u256 {
            self.user_withdrawal_len.read(user)
        }

        /// @notice Reads the dust limit
        /// @return The current dust limit
        fn dust_limit(self: @ContractState) -> u256 {
            self.dust_limit.read()
        }

        /// @notice Calculates the total assets
        /// @return The total assets calculated
        fn total_assets(self: @ContractState) -> u256 {
            self._total_assets()
        }

        /// @notice Calculates the total underlying due
        /// @return The total underlying due calculated
        fn total_underlying_due(self: @ContractState) -> u256 {
            let handled_epoch_withdrawal_len = self.handled_epoch_withdrawal_len.read();
            let epoch = self.epoch.read();
            self._total_underlying_due(handled_epoch_withdrawal_len, epoch)
        }

        /// @notice Calculates the withdrawal exchange rate for a given epoch
        /// @param epoch The epoch for which to calculate the exchange rate
        /// @return The withdrawal exchange rate for the specified epoch
        fn withdrawal_exchange_rate(self: @ContractState, epoch: u256) -> u256 {
            self._withdrawal_exchange_rate(epoch)
        }

        /// @notice Reads the withdrawal pool for a given epoch
        /// @param epoch The epoch for which to read the withdrawal pool
        /// @return The withdrawal pool for the specified epoch
        fn withdrawal_pool(self: @ContractState, epoch: u256) -> u256 {
            self.withdrawal_pool.read(epoch)
        }

        /// @notice Reads the withdrawal share for a given epoch
        /// @param epoch The epoch for which to read the withdrawal share
        /// @return The withdrawal share for the specified epoch
        fn withdrawal_share(self: @ContractState, epoch: u256) -> u256 {
            self.withdrawal_share.read(epoch)
        }


        /// @notice Sets the token for this contract
        /// @dev Only callable by the pooling manager
        /// @param token The contract address of the token
        fn initialiser(ref self: ContractState, token: ContractAddress) {
            self._assert_only_pooling_manager();
            self.token.write(token);
        }

        /// @notice Sets new performance fees
        /// @dev Only callable by the owner of the contract
        /// @param new_performance_fees The new performance fees value to be set
        fn set_performance_fees(ref self: ContractState, new_performance_fees: u256) {
            self._assert_only_owner();
            self._set_performance_fees(new_performance_fees);
            let l1_strategy = self.l1_strategy.read();
            let pooling_manager = self.pooling_manager.read();
            let pooling_manager_disp = IPoolingManagerDispatcher {
                contract_address: pooling_manager
            };
            pooling_manager_disp
                .emit_performance_fees_updated_event(l1_strategy, new_performance_fees);
        }

        /// @notice Sets new deposit limits
        /// @dev Only callable by the owner of the contract
        /// @param new_deposit_limit_low The new lower limit for deposits
        /// @param new_deposit_limit_high The new upper limit for deposits
        fn set_deposit_limit(
            ref self: ContractState, new_deposit_limit_low: u256, new_deposit_limit_high: u256
        ) {
            self._assert_only_owner();
            self._set_deposit_limit(new_deposit_limit_low, new_deposit_limit_high);
            let l1_strategy = self.l1_strategy.read();
            let pooling_manager = self.pooling_manager.read();
            let pooling_manager_disp = IPoolingManagerDispatcher {
                contract_address: pooling_manager
            };
            pooling_manager_disp
                .emit_deposit_limit_updated_event(
                    l1_strategy, new_deposit_limit_low, new_deposit_limit_high
                );
        }

        /// @notice Sets new withdrawal limits
        /// @dev Only callable by the owner of the contract
        /// @param new_withdrawal_limit_low The new lower limit for withdrawals
        /// @param new_withdrawal_limit_high The new upper limit for withdrawals
        fn set_withdrawal_limit(
            ref self: ContractState, new_withdrawal_limit_low: u256, new_withdrawal_limit_high: u256
        ) {
            self._assert_only_owner();
            self._set_withdrawal_limit(new_withdrawal_limit_low, new_withdrawal_limit_high);
            let l1_strategy = self.l1_strategy.read();
            let pooling_manager = self.pooling_manager.read();
            let pooling_manager_disp = IPoolingManagerDispatcher {
                contract_address: pooling_manager
            };
            pooling_manager_disp
                .emit_withdrawal_limit_updated_event(
                    l1_strategy, new_withdrawal_limit_low, new_withdrawal_limit_high
                );
        }

        /// @notice Sets a new withdrawal epoch delay
        /// @dev Only callable by the owner of the contract
        /// @param new_withdrawal_epoch_delay The new withdrawal epoch delay to be set
        fn set_withdrawal_epoch_delay(ref self: ContractState, new_withdrawal_epoch_delay: u256) {
            self._assert_only_owner();
            self._set_withdrawal_epoch_delay(new_withdrawal_epoch_delay);
            let l1_strategy = self.l1_strategy.read();
            let pooling_manager = self.pooling_manager.read();
            let pooling_manager_disp = IPoolingManagerDispatcher {
                contract_address: pooling_manager
            };
            pooling_manager_disp
                .emit_withdrawal_epoch_delay_updated_event(l1_strategy, new_withdrawal_epoch_delay);
        }

        /// @notice Sets a new dust limit
        /// @dev Only callable by the owner of the contract
        /// @param new_dust_limit The new dust limit to be set
        fn set_dust_limit(ref self: ContractState, new_dust_limit: u256) {
            self._assert_only_owner();
            self._set_dust_limit(new_dust_limit);
            let l1_strategy = self.l1_strategy.read();
            let pooling_manager = self.pooling_manager.read();
            let pooling_manager_disp = IPoolingManagerDispatcher {
                contract_address: pooling_manager
            };
            pooling_manager_disp.emit_dust_limit_updated_event(l1_strategy, new_dust_limit);
        }


        /// @notice Allows a user to deposit assets into the contract
        /// @dev Checks if the deposit amount is within the set limits before accepting the deposit
        /// @param assets The amount of assets to deposit
        /// @param receiver The address to receive the minted shares
        /// @param referal The referral address for the deposit
        fn deposit(
            ref self: ContractState,
            assets: u256,
            receiver: ContractAddress,
            referal: ContractAddress
        ) {
            let deposit_limit_low = self.deposit_limit_low.read();
            let deposit_limit_high = self.deposit_limit_high.read();

            assert(assets >= deposit_limit_low, Errors::LOW_LIMIT);
            assert(assets <= deposit_limit_high, Errors::HIGH_LIMIT);

            let underlying = self.underlying.read();
            let erc20_disp = ERC20ABIDispatcher { contract_address: underlying };
            let caller = get_caller_address();
            let this = get_contract_address();
            erc20_disp.transferFrom(caller, this, assets);
            let buffer = self.buffer.read();
            let new_buffer = buffer + assets;
            self.buffer.write(new_buffer);

            let shares = self._convert_to_shares(assets);
            let token = self.token.read();
            let token_disp = ITokenDispatcher { contract_address: token };
            token_disp.mint(receiver, shares);

            let l1_strategy = self.l1_strategy.read();
            let pooling_manager = self.pooling_manager.read();
            let pooling_manager_disp = IPoolingManagerDispatcher {
                contract_address: pooling_manager
            };
            pooling_manager_disp
                .emit_deposit_event(l1_strategy, caller, receiver, assets, shares, referal);
        }

        /// @notice Allows a user to request a withdrawal from the contract
        /// @dev Checks if the withdrawal amount is within the set limits before processing the withdrawal
        /// @param shares The amount of shares to withdraw
        fn request_withdrawal(ref self: ContractState, shares: u256) {
            let withdrawal_limit_low = self.withdrawal_limit_low.read();
            let withdrawal_limit_high = self.withdrawal_limit_high.read();
            assert(shares >= withdrawal_limit_low, Errors::LOW_LIMIT);
            assert(shares <= withdrawal_limit_high, Errors::HIGH_LIMIT);

            let token = self.token.read();
            let token_disp = ITokenDispatcher { contract_address: token };
            let caller = get_caller_address();
            token_disp.burn(caller, shares);

            let epoch = self.epoch.read();
            let assets = self._convert_to_assets(shares);
            let withdrawal_pool_share = (assets * CONSTANTS::WAD)
                / self._withdrawal_exchange_rate(epoch);

            let withdrawal_pool = self.withdrawal_pool.read(epoch);
            let withdrawal_share = self.withdrawal_share.read(epoch);
            self.withdrawal_pool.write(epoch, withdrawal_pool + assets);
            self.withdrawal_share.write(epoch, withdrawal_share + withdrawal_pool_share);

            let user_withdrawal_len = self.user_withdrawal_len.read(caller);
            self
                .withdrawal_info
                .write(
                    (caller, user_withdrawal_len),
                    WithdrawalInfo { shares: shares, epoch: epoch, claimed: false }
                );

            let l1_strategy = self.l1_strategy.read();
            let pooling_manager = self.pooling_manager.read();
            let pooling_manager_disp = IPoolingManagerDispatcher {
                contract_address: pooling_manager
            };
            pooling_manager_disp
                .emit_request_withdrawal_event(
                    l1_strategy, caller, assets, shares, user_withdrawal_len, epoch
                );
        }


        /// @notice Allows a user to claim a withdrawal
        /// @dev Validates that the withdrawal is ready to be claimed and processes it
        /// @param id The unique identifier of the withdrawal request
        fn claim_withdrawal(ref self: ContractState, id: u256) {
            let caller = get_caller_address();
            let withdrawal_info = self.withdrawal_info.read((caller, id));
            assert(!withdrawal_info.claimed, Errors::ALREADY_CLAIMED);
            let handled_epoch_withdrawal_len = self.handled_epoch_withdrawal_len.read();
            assert(
                handled_epoch_withdrawal_len > withdrawal_info.epoch, Errors::WITHDRAWAL_NOT_REDY
            );

            self
                .withdrawal_info
                .write(
                    (caller, id),
                    WithdrawalInfo {
                        shares: withdrawal_info.shares, epoch: withdrawal_info.epoch, claimed: true
                    }
                );

            let withdrawal_exchange_rate = self._withdrawal_exchange_rate(withdrawal_info.epoch);
            let assets = (withdrawal_exchange_rate * withdrawal_info.shares) / CONSTANTS::WAD;

            let withdrawal_pool = self.withdrawal_pool.read(withdrawal_info.epoch);
            let withdrawal_share = self.withdrawal_share.read(withdrawal_info.epoch);
            self.withdrawal_pool.write(withdrawal_info.epoch, withdrawal_pool - assets);
            self
                .withdrawal_share
                .write(withdrawal_info.epoch, withdrawal_share - withdrawal_info.shares);

            let underlying = self.underlying.read();
            let underlying_disp = ERC20ABIDispatcher { contract_address: underlying };
            underlying_disp.transfer(caller, assets);

            let l1_strategy = self.l1_strategy.read();
            let pooling_manager = self.pooling_manager.read();
            let pooling_manager_disp = IPoolingManagerDispatcher {
                contract_address: pooling_manager
            };
            pooling_manager_disp.emit_claim_withdrawal_event(l1_strategy, caller, id, assets);
        }


        /// @notice Handles the report from the L1 strategy
        /// @dev Only callable by the pooling manager, processes the report and updates the contract state
        /// @param l1_net_asset_value The net asset value reported from L1
        /// @param underlying_bridged_amount The amount of underlying asset bridged
        /// @return StrategyReportL2 object containing the strategy report data
        fn handle_report(
            ref self: ContractState, l1_net_asset_value: u256, underlying_bridged_amount: u256
        ) -> StrategyReportL2 {
            self._assert_only_pooling_manager();

            let epoch = self.epoch.read();
            let prev_l1_net_asset_value = self.l1_net_asset_value.read();
            let prev_underlying_transit = self.underlying_transit.read();

            let sent_to_l1 = prev_l1_net_asset_value + prev_underlying_transit;
            let received_from_l1 = l1_net_asset_value + underlying_bridged_amount;

            let handled_epoch_withdrawal_len = self.handled_epoch_withdrawal_len.read();
            let buffer_mem = self.buffer.read() + underlying_bridged_amount;

            let mut profit = 0;

            if (received_from_l1 < sent_to_l1) {
                let underlying_loss = sent_to_l1 - received_from_l1;
                let total_underlying = buffer_mem + l1_net_asset_value;
                let total_underlying_due = self
                    ._total_underlying_due(handled_epoch_withdrawal_len, epoch);
                let amount_to_consider = total_underlying + total_underlying_due;
                let mut i = handled_epoch_withdrawal_len;
                loop {
                    if (i > epoch) {
                        break ();
                    }
                    let withdrawal_pool = self.withdrawal_pool.read(i);
                    let withdrawal_epoch_loss_incured = (underlying_loss * withdrawal_pool)
                        / amount_to_consider;
                    self.withdrawal_pool.write(i, withdrawal_pool - withdrawal_epoch_loss_incured);
                    i += 1;
                }
            } else {
                // Share price increase, performance_fee is taken
                profit = received_from_l1 - sent_to_l1;
            }

            let mut remaining_buffer_mem = buffer_mem;
            let mut cumulatif_due_underlying = 0;
            let withdrawal_epoch_delay = self.withdrawal_epoch_delay.read();

            if (epoch >= withdrawal_epoch_delay) {
                let mut new_handled_epoch_withdrawal_len = handled_epoch_withdrawal_len;
                let mut j = handled_epoch_withdrawal_len;
                let limit_epoch = epoch - withdrawal_epoch_delay;
                loop {
                    if (j > limit_epoch) {
                        break ();
                    }

                    let withdrawal_pool = self.withdrawal_pool.read(j);

                    if (remaining_buffer_mem >= withdrawal_pool) {
                        remaining_buffer_mem -= withdrawal_pool;
                        new_handled_epoch_withdrawal_len += 1;
                    } else {
                        cumulatif_due_underlying += withdrawal_pool - remaining_buffer_mem;
                    }

                    j += 1;
                };
                if (new_handled_epoch_withdrawal_len > handled_epoch_withdrawal_len) {
                    self.handled_epoch_withdrawal_len.write(new_handled_epoch_withdrawal_len);
                }
            }

            let new_epoch = epoch + 1;
            self.epoch.write(new_epoch);
            self.l1_net_asset_value.write(l1_net_asset_value);

            let token = self.token.read();
            let token_disp = ERC20ABIDispatcher { contract_address: token };
            let decimals = token_disp.decimals();
            let l1_strategy = self.l1_strategy.read();
            let one_share_unit = MATH::pow(10, decimals.into());

            if (cumulatif_due_underlying > 0) {
                // We need more underlying from L1
                let underlying_request_amount = cumulatif_due_underlying - remaining_buffer_mem;
                self.buffer.write(remaining_buffer_mem);
                self.underlying_transit.write(0);

                self._check_profit_and_mint(profit, token);

                let new_share_price = self._convert_to_assets(one_share_unit);

                StrategyReportL2 {
                    l1_strategy: l1_strategy,
                    action_id: 2,
                    amount: underlying_request_amount,
                    new_share_price: new_share_price
                }
            } else {
                let dust_limit_factor = self.dust_limit.read();
                let dust_limit = (l1_net_asset_value * dust_limit_factor) / CONSTANTS::WAD;

                if (dust_limit > remaining_buffer_mem) {
                    // We are fine
                    self.buffer.write(remaining_buffer_mem);
                    self.underlying_transit.write(0);

                    self._check_profit_and_mint(profit, token);

                    let new_share_price = self._convert_to_assets(one_share_unit);

                    StrategyReportL2 {
                        l1_strategy: l1_strategy,
                        action_id: 1,
                        amount: 0,
                        new_share_price: new_share_price
                    }
                } else {
                    // We deposit underlying to L1
                    self.buffer.write(0);
                    self.underlying_transit.write(remaining_buffer_mem);

                    self._check_profit_and_mint(profit, token);

                    let new_share_price = self._convert_to_assets(one_share_unit);

                    StrategyReportL2 {
                        l1_strategy: l1_strategy,
                        action_id: 0,
                        amount: remaining_buffer_mem,
                        new_share_price: new_share_price
                    }
                }
            }
        }
    }

    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// @notice Asserts that the caller is the pooling manager
        fn _assert_only_pooling_manager(self: @ContractState) {
            let caller = get_caller_address();
            let pooling_manager = self.pooling_manager.read();
            assert(caller == pooling_manager, Errors::INVALID_CALLER);
        }

        /// @notice Asserts that the caller has the owner role
        fn _assert_only_owner(self: @ContractState) {
            let caller = get_caller_address();
            let pooling_manager = self.pooling_manager.read();
            let access_disp = IAccessControlDispatcher { contract_address: pooling_manager };
            let has_role = access_disp.has_role(0, caller);
            assert(has_role, Errors::INVALID_CALLER);
        }

        /// @notice Calculates the total underlying due up to the current epoch
        /// @param handled_epoch_withdrawal_len The length of the handled epoch withdrawal
        /// @param current_epoch The current epoch
        /// @return The total underlying due
        fn _total_underlying_due(
            self: @ContractState, handled_epoch_withdrawal_len: u256, current_epoch: u256
        ) -> u256 {
            let mut i = handled_epoch_withdrawal_len;
            let mut acc = 0;
            loop {
                if (i > current_epoch) {
                    break ();
                }
                let withdrawal_pool = self.withdrawal_pool.read(i);
                acc += withdrawal_pool;
                i += 1;
            };
            acc
        }


        /// @notice Calculates the total assets of the contract
        /// @return The total assets
        fn _total_assets(self: @ContractState) -> u256 {
            let epoch = self.epoch.read();
            let handled_epoch_withdrawal_len = self.handled_epoch_withdrawal_len.read();
            let total_underlying_due = self
                ._total_underlying_due(handled_epoch_withdrawal_len, epoch);
            let buffer = self.buffer.read();
            let l1_net_asset_value = self.l1_net_asset_value.read();
            let underlying_transit = self.underlying_transit.read();
            (buffer + l1_net_asset_value + underlying_transit) - total_underlying_due
        }


        /// @notice Converts a given amount of assets to shares
        /// @param assets The amount of assets to convert
        /// @return The equivalent amount of shares
        fn _convert_to_shares(self: @ContractState, assets: u256) -> u256 {
            let token = self.token.read();
            let erc20_disp = ERC20ABIDispatcher { contract_address: token };
            let total_supply = erc20_disp.total_supply();
            let total_assets = self._total_assets();
            (assets * (total_supply + 1)) / (total_assets + 1)
        }

        /// @notice Converts a given amount of shares to assets
        /// @param shares The amount of shares to convert
        /// @return The equivalent amount of assets
        fn _convert_to_assets(self: @ContractState, shares: u256) -> u256 {
            let token = self.token.read();
            let erc20_disp = ERC20ABIDispatcher { contract_address: token };
            let total_supply = erc20_disp.total_supply();
            let total_assets = self._total_assets();
            (shares * (total_assets + 1)) / (total_supply + 1)
        }

        /// @notice Calculates the withdrawal exchange rate for a given epoch
        /// @param epoch The epoch for which to calculate the rate
        /// @return The withdrawal exchange rate
        fn _withdrawal_exchange_rate(self: @ContractState, epoch: u256) -> u256 {
            let withdrawal_pool = self.withdrawal_pool.read(epoch);
            let withdrawal_share = self.withdrawal_share.read(epoch);
            if (withdrawal_pool.is_zero()) {
                0
            } else {
                (withdrawal_pool * CONSTANTS::WAD) / withdrawal_share
            }
        }


        /// @notice Sets the performance fees for the contract
        /// @param new_performance_fees The new performance fees
        fn _set_performance_fees(ref self: ContractState, new_performance_fees: u256) {
            assert(new_performance_fees < CONSTANTS::WAD, Errors::INVALID_FEES);
            self.performance_fees.write(new_performance_fees);
        }

        /// @notice Sets the deposit limits for the contract
        /// @param new_deposit_limit_low The new low limit for deposits
        /// @param new_deposit_limit_high The new high limit for deposits
        fn _set_deposit_limit(
            ref self: ContractState, new_deposit_limit_low: u256, new_deposit_limit_high: u256
        ) {
            assert(new_deposit_limit_low.is_non_zero(), Errors::ZERO_AMOUNT);
            assert(new_deposit_limit_high > new_deposit_limit_low, Errors::INVALID_LIMIT);
            self.deposit_limit_low.write(new_deposit_limit_low);
            self.deposit_limit_high.write(new_deposit_limit_high);
        }

        /// @notice Sets the withdrawal limits for the contract
        /// @param new_withdrawal_limit_low The new low limit for withdrawals
        /// @param new_withdrawal_limit_high The new high limit for withdrawals
        fn _set_withdrawal_limit(
            ref self: ContractState, new_withdrawal_limit_low: u256, new_withdrawal_limit_high: u256
        ) {
            assert(new_withdrawal_limit_low > 0, Errors::ZERO_AMOUNT);
            assert(new_withdrawal_limit_high > new_withdrawal_limit_low, Errors::INVALID_LIMIT);
            self.withdrawal_limit_low.write(new_withdrawal_limit_low);
            self.withdrawal_limit_high.write(new_withdrawal_limit_high);
        }

        /// @notice Sets the withdrawal epoch delay for the contract
        /// @param new_withdrawal_epoch_delay The new withdrawal epoch delay
        fn _set_withdrawal_epoch_delay(ref self: ContractState, new_withdrawal_epoch_delay: u256) {
            assert(new_withdrawal_epoch_delay.is_non_zero(), Errors::ZERO_AMOUNT);
            self.withdrawal_epoch_delay.write(new_withdrawal_epoch_delay);
        }

        /// @notice Sets the dust limit for the contract
        /// @param new_dust_limit The new dust limit
        fn _set_dust_limit(ref self: ContractState, new_dust_limit: u256) {
            assert(new_dust_limit.is_non_zero(), Errors::ZERO_AMOUNT);
            self.dust_limit.write(new_dust_limit);
        }

        fn _check_profit_and_mint(ref self: ContractState, profit: u256, token: ContractAddress) {
            if (profit > 0) {
                let performance_fees = self.performance_fees.read();
                let performance_fees_from_profit = (profit * performance_fees) / CONSTANTS::WAD;
                let shares_to_mint = self._convert_to_shares(performance_fees_from_profit);
                let pooling_manager = self.pooling_manager.read();
                let pooling_manager_disp = IPoolingManagerDispatcher {
                    contract_address: pooling_manager
                };
                let fees_recipient = pooling_manager_disp.fees_recipient();
                let token_disp = ITokenDispatcher { contract_address: token };
                token_disp.mint(fees_recipient, shares_to_mint);
            }
        }
    }
}
