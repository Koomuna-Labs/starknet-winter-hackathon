/// @title Factory Module
/// @notice Responsible for deploying strategies and their associated tokens.
#[starknet::contract]
mod MockFactory {
    // Core lib imports.
    use core::result::ResultTrait;
    use starknet::{
        get_caller_address, ContractAddress, contract_address_const, ClassHash,
        eth_address::EthAddress, Zeroable
    };
    use starknet::syscalls::deploy_syscall;
    use core::poseidon::poseidon_hash_span;


    // OZ imports
    use openzeppelin::access::accesscontrol::interface::{
        IAccessControlDispatcher, IAccessControlDispatcherTrait
    };
    use openzeppelin::token::erc20::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait};
    use openzeppelin::upgrades::UpgradeableComponent;


    // Local imports.
    use nimbora_yields::factory::interface::{IFactory};
    use nimbora_yields::pooling_manager::interface::{
        IPoolingManagerDispatcher, IPoolingManagerDispatcherTrait
    };

    // Components
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    impl InternalUpgradeableImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        pooling_manager: ContractAddress,
        token_class_hash: ClassHash,
        token_manager_class_hash: ClassHash
    }


    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        TokenHashUpdated: TokenHashUpdated,
        TokenManagerHashUpdated: TokenManagerHashUpdated
    }

    #[derive(Drop, starknet::Event)]
    struct TokenHashUpdated {
        previous_hash: ClassHash,
        new_hash: ClassHash
    }

    #[derive(Drop, starknet::Event)]
    struct TokenManagerHashUpdated {
        previous_hash: ClassHash,
        new_hash: ClassHash
    }


    mod Errors {
        const ZERO_ADDRESS: felt252 = 'Address is zero';
        const ZERO_HASH: felt252 = 'Hash is zero';
        const INVALID_CALLER: felt252 = 'Invalid caller';
    }

    /// @notice Constructor for the Factory contract.
    /// @param pooling_manager The address of the pooling manager.
    /// @param token_class_hash The class hash of the token.
    /// @param token_manager_class_hash The class hash of the token manager.
    #[constructor]
    fn constructor(
        ref self: ContractState,
        pooling_manager: ContractAddress,
        token_class_hash: ClassHash,
        token_manager_class_hash: ClassHash
    ) {
        assert(pooling_manager.is_non_zero(), Errors::ZERO_ADDRESS);
        self.pooling_manager.write(pooling_manager);
        self._set_token_class_hash(token_class_hash);
        self._set_token_manager_class_hash(token_manager_class_hash);
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
    impl Factory of IFactory<ContractState> {
        /// @notice Reads the class hash of the token manager
        /// @return The class hash of the token manager
        fn token_manager_class_hash(self: @ContractState) -> ClassHash {
            self.token_manager_class_hash.read()
        }

        /// @notice Reads the class hash of the token
        /// @return The class hash of the token
        fn token_class_hash(self: @ContractState) -> ClassHash {
            self.token_class_hash.read()
        }

        /// @notice Reads the pooling manager contract address
        /// @return The address of the pooling manager
        fn pooling_manager_address(self: @ContractState) -> ContractAddress {
            self.pooling_manager.read()
        }

        /// @notice Deploys a new strategy with specified parameters
        /// @dev Only callable by the owner of the contract
        /// @param l1_strategy The Ethereum address of the L1 strategy
        /// @param underlying The contract address of the underlying asset
        /// @param token_name The name for the new token
        /// @param token_symbol The symbol for the new token
        /// @param performance_fees The performance fees for the strategy
        /// @param min_deposit The minimum deposit limit
        /// @param max_deposit The maximum deposit limit
        /// @param min_withdrawal The minimum withdrawal limit
        /// @param max_withdrawal The maximum withdrawal limit
        /// @param withdrawal_epoch_delay The delay in epochs for withdrawals
        /// @param dust_limit The dust limit for the strategy
        /// @return The addresses of the deployed token manager and token
        fn deploy_strategy(
            ref self: ContractState,
            l1_strategy: EthAddress,
            underlying: ContractAddress,
            token_name: felt252,
            token_symbol: felt252,
            performance_fees: u256,
            min_deposit: u256,
            max_deposit: u256,
            min_withdrawal: u256,
            max_withdrawal: u256,
            withdrawal_epoch_delay: u256,
            dust_limit: u256
        ) -> (ContractAddress, ContractAddress) {
            self._assert_only_owner();
            let (token_manager_salt, token_salt) = self
                ._compute_salt_for_strategy(l1_strategy, underlying, token_name, token_symbol);
            let pooling_manager = self.pooling_manager.read();
            let mut constructor_token_manager_calldata = array![
                pooling_manager.into(),
                l1_strategy.into(),
                underlying.into(),
                performance_fees.low.into(),
                performance_fees.high.into(),
                min_deposit.low.into(),
                min_deposit.high.into(),
                max_deposit.low.into(),
                max_deposit.high.into(),
                min_withdrawal.low.into(),
                min_withdrawal.high.into(),
                max_withdrawal.low.into(),
                max_withdrawal.high.into(),
                withdrawal_epoch_delay.low.into(),
                withdrawal_epoch_delay.high.into(),
                dust_limit.low.into(),
                dust_limit.high.into()
            ];

            let (token_manager_deployed_address, _) = deploy_syscall(
                self.token_manager_class_hash.read(),
                token_manager_salt,
                constructor_token_manager_calldata.span(),
                false
            )
                .expect('failed to deploy tm');

            let token_disp = ERC20ABIDispatcher { contract_address: underlying };
            let decimals = token_disp.decimals();

            let mut constructor_token_calldata = array![
                token_manager_deployed_address.into(),
                token_name.into(),
                token_symbol.into(),
                decimals.into()
            ];

            let (token_deployed_address, _) = deploy_syscall(
                self.token_class_hash.read(), token_salt, constructor_token_calldata.span(), false
            )
                .expect('failed to deploy t');

            let pooling_manager = self.pooling_manager.read();
            let manager_disp = IPoolingManagerDispatcher { contract_address: pooling_manager };
            manager_disp
                .register_strategy(
                    token_manager_deployed_address,
                    token_deployed_address,
                    l1_strategy,
                    underlying,
                    performance_fees,
                    min_deposit,
                    max_deposit,
                    min_withdrawal,
                    max_withdrawal
                );
            (token_manager_deployed_address, token_deployed_address)
        }


        /// @notice Sets a new class hash for the token manager
        /// @dev Only callable by the owner of the contract
        /// @param new_token_manager_class_hash The new class hash to be set for the token manager
        fn set_token_manager_class_hash(
            ref self: ContractState, new_token_manager_class_hash: ClassHash,
        ) {
            self._assert_only_owner();
            self._set_token_manager_class_hash(new_token_manager_class_hash);
            let pooling_manager = self.pooling_manager.read();
            let pooling_manager_disp = IPoolingManagerDispatcher {
                contract_address: pooling_manager
            };
            pooling_manager_disp
                .emit_token_manager_class_hash_updated_event(new_token_manager_class_hash);
        }

        /// @notice Sets a new class hash for the token
        /// @dev Only callable by the owner of the contract
        /// @param new_token_class_hash The new class hash to be set for the token
        fn set_token_class_hash(ref self: ContractState, new_token_class_hash: ClassHash,) {
            self._assert_only_owner();
            self._set_token_class_hash(new_token_class_hash);
            let pooling_manager = self.pooling_manager.read();
            let pooling_manager_disp = IPoolingManagerDispatcher {
                contract_address: pooling_manager
            };
            pooling_manager_disp.emit_token_class_hash_updated_event(new_token_class_hash);
        }
    }


    #[generate_trait]
    impl InternalImpl of InternalTrait {
        /// @notice Asserts that the caller has the owner role
        /// @dev Verifies the caller's role using the Access Control Dispatcher
        fn _assert_only_owner(self: @ContractState) {
            let caller = get_caller_address();
            let pooling_manager = self.pooling_manager.read();
            let access_disp = IAccessControlDispatcher { contract_address: pooling_manager };
            let has_role = access_disp.has_role(0, caller);
            assert(has_role, Errors::INVALID_CALLER);
        }


        /// @notice Computes the salts for token manager and token based on strategy parameters
        /// @param l1_strategy The Ethereum address of the L1 strategy
        /// @param underlying The contract address of the underlying asset
        /// @param token_name The name of the token
        /// @param token_symbol The symbol of the token
        /// @return A tuple containing the salts for the token manager and token
        fn _compute_salt_for_strategy(
            self: @ContractState,
            l1_strategy: EthAddress,
            underlying: ContractAddress,
            token_name: felt252,
            token_symbol: felt252
        ) -> (felt252, felt252) {
            let mut token_manager_data = array![];
            token_manager_data.append('TOKEN_MANAGER');
            token_manager_data.append(l1_strategy.into());
            token_manager_data.append(underlying.into());
            let token_manager_salt = poseidon_hash_span(token_manager_data.span());

            let mut token_data = array![];
            token_data.append('TOKEN');
            token_data.append(token_name.into());
            token_data.append(token_symbol.into());
            let token_salt = poseidon_hash_span(token_data.span());

            (token_manager_salt, token_salt)
        }


        /// @notice Sets the class hash for the token manager
        /// @dev Ensures that the provided class hash is non-zero before updating
        /// @param token_manager_hash The new class hash to be set for the token manager
        fn _set_token_manager_class_hash(ref self: ContractState, token_manager_hash: ClassHash) {
            assert(token_manager_hash.is_non_zero(), Errors::ZERO_HASH);
            self.token_manager_class_hash.write(token_manager_hash);
        }

        /// @notice Sets the class hash for the token
        /// @dev Ensures that the provided class hash is non-zero before updating
        /// @param token_hash The new class hash to be set for the token
        fn _set_token_class_hash(ref self: ContractState, token_hash: ClassHash) {
            assert(token_hash.is_non_zero(), Errors::ZERO_HASH);
            self.token_class_hash.write(token_hash);
        }
    }
}
