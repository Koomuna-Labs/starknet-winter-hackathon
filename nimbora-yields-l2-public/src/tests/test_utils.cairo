use core::option::OptionTrait;
use core::traits::TryInto;
use core::traits::Into;
// Nimbora yields contracts
use nimbora_yields::pooling_manager::pooling_manager::{PoolingManager};
use nimbora_yields::pooling_manager::interface::{
    IPoolingManagerDispatcher, IPoolingManagerDispatcherTrait, StrategyReportL1
};
use nimbora_yields::factory::factory::{Factory};
use nimbora_yields::factory::interface::{IFactoryDispatcher, IFactoryDispatcherTrait};
use nimbora_yields::token_manager::token_manager::{TokenManager};
use nimbora_yields::token_manager::interface::{
    ITokenManagerDispatcher, ITokenManagerDispatcherTrait, WithdrawalInfo, StrategyReportL2
};
use nimbora_yields::token_bridge::token_bridge::{TokenBridge};
use nimbora_yields::token_bridge::token_mock::{TokenMock};
use nimbora_yields::token_bridge::interface::{
    ITokenBridgeDispatcher, IMintableTokenDispatcher, IMintableTokenDispatcherTrait
};

use openzeppelin::{
    token::erc20::interface::{ERC20ABIDispatcher, ERC20ABIDispatcherTrait},
    access::accesscontrol::{
        AccessControlComponent, interface::{IAccessControlDispatcher, IAccessControlDispatcherTrait}
    },
    upgrades::interface::{IUpgradeableDispatcher, IUpgradeable, IUpgradeableDispatcherTrait}
};

use starknet::{
    get_contract_address, deploy_syscall, ClassHash, contract_address_const, ContractAddress,
    get_block_timestamp, EthAddress, Zeroable
};
use starknet::class_hash::Felt252TryIntoClassHash;
use starknet::account::{Call};
use snforge_std::{
    declare, ContractClassTrait, start_prank, CheatTarget, ContractClass, PrintTrait, stop_prank,
    start_warp, stop_warp
};

fn deploy_tokens(
    initial_supply: u256, recipient: ContractAddress
) -> (ERC20ABIDispatcher, ERC20ABIDispatcher, ERC20ABIDispatcher) {
    let contract = declare('TokenMock');

    let mut constructor_args: Array<felt252> = ArrayTrait::new();
    Serde::serialize(@initial_supply, ref constructor_args);
    Serde::serialize(@recipient, ref constructor_args);
    let contract_address_1 = contract.deploy(@constructor_args).unwrap();
    let contract_address_2 = contract.deploy(@constructor_args).unwrap();
    let contract_address_3 = contract.deploy(@constructor_args).unwrap();

    return (
        ERC20ABIDispatcher { contract_address: contract_address_1 },
        ERC20ABIDispatcher { contract_address: contract_address_2 },
        ERC20ABIDispatcher { contract_address: contract_address_3 }
    );
}

fn deploy_token_bridges(
    l2_address_1: ContractAddress,
    l1_bridge_1: felt252,
    l2_address_2: ContractAddress,
    l1_bridge_2: felt252,
    l2_address_3: ContractAddress,
    l1_bridge_3: felt252
) -> (ITokenBridgeDispatcher, ITokenBridgeDispatcher, ITokenBridgeDispatcher) {
    let contract = declare('TokenBridge');

    let mut constructor_args_1: Array<felt252> = ArrayTrait::new();
    Serde::serialize(@l2_address_1, ref constructor_args_1);
    Serde::serialize(@l1_bridge_1, ref constructor_args_1);
    let contract_address_1 = contract.deploy(@constructor_args_1).unwrap();

    let mut constructor_args_2: Array<felt252> = ArrayTrait::new();
    Serde::serialize(@l2_address_2, ref constructor_args_2);
    Serde::serialize(@l1_bridge_2, ref constructor_args_2);
    let contract_address_2 = contract.deploy(@constructor_args_2).unwrap();

    let mut constructor_args_3: Array<felt252> = ArrayTrait::new();
    Serde::serialize(@l2_address_3, ref constructor_args_3);
    Serde::serialize(@l1_bridge_3, ref constructor_args_3);
    let contract_address_3 = contract.deploy(@constructor_args_3).unwrap();

    return (
        ITokenBridgeDispatcher { contract_address: contract_address_1 },
        ITokenBridgeDispatcher { contract_address: contract_address_2 },
        ITokenBridgeDispatcher { contract_address: contract_address_3 }
    );
}

fn deploy_pooling_manager(owner: ContractAddress) -> IPoolingManagerDispatcher {
    let contract = declare('PoolingManager');
    let mut constructor_args: Array<felt252> = ArrayTrait::new();
    Serde::serialize(@owner, ref constructor_args);
    let contract_address = contract.deploy(@constructor_args).unwrap();
    return IPoolingManagerDispatcher { contract_address: contract_address };
}

fn deploy_factory(
    pooling_manager: ContractAddress,
    token_class_hash: ClassHash,
    token_manager_class_hash: ClassHash
) -> IFactoryDispatcher {
    let contract = declare('Factory');
    let mut constructor_args: Array<felt252> = ArrayTrait::new();
    Serde::serialize(@pooling_manager, ref constructor_args);
    Serde::serialize(@token_class_hash, ref constructor_args);
    Serde::serialize(@token_manager_class_hash, ref constructor_args);
    let contract_address = contract.deploy(@constructor_args).unwrap();
    return IFactoryDispatcher { contract_address: contract_address };
}

fn deploy_token_manager() -> ITokenManagerDispatcher {
    let (
        owner,
        fees_recipient,
        l1_pooling_manager,
        pooling_manager,
        factory,
        token_hash,
        token_manager_hash
    ) =
        setup_0();
    let (token_1, token_2, token_3, bridge_1, bridge_2, bridge_3) = setup_1(
        owner, l1_pooling_manager, pooling_manager, fees_recipient, factory
    );
    let mut constructor_args: Array<felt252> = ArrayTrait::new();
    let l1_strategy_1: EthAddress = 2.try_into().unwrap();
    let performance_fees_strategy_1: u256 = 200000000000000000;
    let min_deposit_1: u256 = 100000000000000000;
    let max_deposit_1: u256 = 10000000000000000000;
    let min_withdraw_1: u256 = 200000000000000000;
    let max_withdraw_1: u256 = 2000000000000000000000000;
    let withdrawal_epoch_delay_1: u256 = 2;
    let dust_limit_1: u256 = 1000000000000000000;

    Serde::serialize(@pooling_manager.contract_address, ref constructor_args);
    Serde::serialize(@l1_strategy_1, ref constructor_args);
    Serde::serialize(@token_1.contract_address, ref constructor_args);
    Serde::serialize(@performance_fees_strategy_1, ref constructor_args);
    Serde::serialize(@min_deposit_1, ref constructor_args);
    Serde::serialize(@max_deposit_1, ref constructor_args);
    Serde::serialize(@min_withdraw_1, ref constructor_args);
    Serde::serialize(@max_withdraw_1, ref constructor_args);
    Serde::serialize(@withdrawal_epoch_delay_1, ref constructor_args);
    Serde::serialize(@dust_limit_1, ref constructor_args);

    let contract = ContractClass { class_hash: token_manager_hash };

    let contract_address = contract.deploy(@constructor_args).unwrap();
    return ITokenManagerDispatcher { contract_address: contract_address };
}

fn setup_0() -> (
    ContractAddress,
    ContractAddress,
    EthAddress,
    IPoolingManagerDispatcher,
    IFactoryDispatcher,
    ClassHash,
    ClassHash
) {
    let owner = contract_address_const::<2300>();
    let fees_recipient = contract_address_const::<2400>();
    let l1_pooling_manager: EthAddress = 100.try_into().unwrap();
    let pooling_manager = deploy_pooling_manager(owner);
    let token_hash = declare('Token');
    let token_manager_hash = declare('TokenManager');
    let factory = deploy_factory(
        pooling_manager.contract_address, token_hash.class_hash, token_manager_hash.class_hash
    );
    (
        owner,
        fees_recipient,
        l1_pooling_manager,
        pooling_manager,
        factory,
        token_hash.class_hash,
        token_manager_hash.class_hash
    )
}

fn setup_1(
    owner: ContractAddress,
    l1_pooling_manager: EthAddress,
    pooling_manager: IPoolingManagerDispatcher,
    fees_recipient: ContractAddress,
    factory: IFactoryDispatcher
) -> (
    ERC20ABIDispatcher,
    ERC20ABIDispatcher,
    ERC20ABIDispatcher,
    ITokenBridgeDispatcher,
    ITokenBridgeDispatcher,
    ITokenBridgeDispatcher
) {
    // Initialise
    start_prank(CheatTarget::One(pooling_manager.contract_address), owner);
    pooling_manager.set_fees_recipient(fees_recipient);
    pooling_manager.set_l1_pooling_manager(l1_pooling_manager);
    pooling_manager.set_factory(factory.contract_address);
    stop_prank(CheatTarget::One(pooling_manager.contract_address));

    // Deploy tokens and bridges
    let (l1_bridge_1, l1_bridge_2, l1_bridge_3) = (
        111.try_into().unwrap(), 112.try_into().unwrap(), 113.try_into().unwrap()
    );
    let (token_1, token_2, token_3) = deploy_tokens(1000000000000000000000, owner);
    let (bridge_1, bridge_2, bridge_3) = deploy_token_bridges(
        token_1.contract_address,
        l1_bridge_1,
        token_2.contract_address,
        l1_bridge_2,
        token_3.contract_address,
        l1_bridge_3
    );
    (token_1, token_2, token_3, bridge_1, bridge_2, bridge_3)
}

fn setup_2(
    pooling_manager: IPoolingManagerDispatcher,
    owner: ContractAddress,
    token_1: ContractAddress,
    token_2: ContractAddress,
    token_3: ContractAddress,
    bridge_1: ContractAddress,
    bridge_2: ContractAddress,
    bridge_3: ContractAddress
) {
    let l1_bridge_1 = 5;
    let l1_bridge_2 = 6;
    let l1_bridge_3 = 7;
    start_prank(CheatTarget::One(pooling_manager.contract_address), owner);
    pooling_manager.register_underlying(token_1, bridge_1, l1_bridge_1);
    pooling_manager.register_underlying(token_2, bridge_2, l1_bridge_2);
    pooling_manager.register_underlying(token_3, bridge_3, l1_bridge_3);
    stop_prank(CheatTarget::One(pooling_manager.contract_address));
}

fn deploy_strategy() -> (ContractAddress, ContractAddress, IPoolingManagerDispatcher) {
    let (
        owner,
        fees_recipient,
        l1_pooling_manager,
        pooling_manager,
        factory,
        token_hash,
        token_manager_hash
    ) =
        setup_0();
    let (token_1, token_2, token_3, bridge_1, bridge_2, bridge_3) = setup_1(
        owner, l1_pooling_manager, pooling_manager, fees_recipient, factory
    );
    setup_2(
        pooling_manager,
        owner,
        token_1.contract_address,
        token_2.contract_address,
        token_3.contract_address,
        bridge_1.contract_address,
        bridge_2.contract_address,
        bridge_3.contract_address
    );
    let l1_strategy_1: EthAddress = 2.try_into().unwrap();
    let performance_fees_strategy_1 = 200000000000000000;
    let min_deposit_1 = 100000000000000000;
    let max_deposit_1 = 10000000000000000000;
    let min_withdraw_1 = 200000000000000000;
    let max_withdraw_1 = 2000000000000000000000000;
    let withdrawal_epoch_delay_1 = 2;
    let dust_limit_1 = 1000000000000000000;
    let name_1 = 10;
    let symbol_1 = 1000;

    start_prank(CheatTarget::One(factory.contract_address), owner);
    let (token_manager_deployed_address, token_deployed_address) = factory
        .deploy_strategy(
            l1_strategy_1,
            token_1.contract_address,
            name_1,
            symbol_1,
            performance_fees_strategy_1,
            min_deposit_1,
            max_deposit_1,
            min_withdraw_1,
            max_withdraw_1,
            withdrawal_epoch_delay_1,
            dust_limit_1
        );
    stop_prank(CheatTarget::One(factory.contract_address));
    return (token_manager_deployed_address, token_deployed_address, pooling_manager);
}

fn deploy_two_strategy() -> (
    ContractAddress, ContractAddress, IPoolingManagerDispatcher, ContractAddress, ContractAddress
) {
    let (
        owner,
        fees_recipient,
        l1_pooling_manager,
        pooling_manager,
        factory,
        token_hash,
        token_manager_hash
    ) =
        setup_0();
    let (token_1, token_2, token_3, bridge_1, bridge_2, bridge_3) = setup_1(
        owner, l1_pooling_manager, pooling_manager, fees_recipient, factory
    );
    setup_2(
        pooling_manager,
        owner,
        token_1.contract_address,
        token_2.contract_address,
        token_3.contract_address,
        bridge_1.contract_address,
        bridge_2.contract_address,
        bridge_3.contract_address
    );
    let l1_strategy_1: EthAddress = 2.try_into().unwrap();
    let l1_strategy_2: EthAddress = 3.try_into().unwrap();
    let performance_fees_strategy_1 = 200000000000000000;
    let min_deposit_1 = 100000000000000000;
    let max_deposit_1 = 10000000000000000000;
    let min_withdraw_1 = 200000000000000000;
    let max_withdraw_1 = 2000000000000000000000000;
    let withdrawal_epoch_delay_1 = 2;
    let dust_limit_1 = 1000000000000000000;
    let name_1 = 10;
    let symbol_1 = 1000;

    start_prank(CheatTarget::One(factory.contract_address), owner);
    let (token_manager_deployed_address, token_deployed_address) = factory
        .deploy_strategy(
            l1_strategy_1,
            token_1.contract_address,
            name_1,
            symbol_1,
            performance_fees_strategy_1,
            min_deposit_1,
            max_deposit_1,
            min_withdraw_1,
            max_withdraw_1,
            withdrawal_epoch_delay_1,
            dust_limit_1
        );
    let (token_manager_deployed_address2, token_deployed_address2) = factory
        .deploy_strategy(
            l1_strategy_2,
            token_2.contract_address,
            name_1,
            symbol_1,
            performance_fees_strategy_1,
            min_deposit_1,
            max_deposit_1,
            min_withdraw_1,
            max_withdraw_1,
            withdrawal_epoch_delay_1,
            dust_limit_1
        );
    stop_prank(CheatTarget::One(factory.contract_address));
    return (
        token_manager_deployed_address,
        token_deployed_address,
        pooling_manager,
        token_manager_deployed_address2,
        token_deployed_address2
    );
}


fn deploy_three_strategy() -> (
    ContractAddress,
    ContractAddress,
    IPoolingManagerDispatcher,
    ContractAddress,
    ContractAddress,
    ContractAddress,
    ContractAddress
) {
    let (
        owner,
        fees_recipient,
        l1_pooling_manager,
        pooling_manager,
        factory,
        token_hash,
        token_manager_hash
    ) =
        setup_0();
    let (token_1, token_2, token_3, bridge_1, bridge_2, bridge_3) = setup_1(
        owner, l1_pooling_manager, pooling_manager, fees_recipient, factory
    );
    setup_2(
        pooling_manager,
        owner,
        token_1.contract_address,
        token_2.contract_address,
        token_3.contract_address,
        bridge_1.contract_address,
        bridge_2.contract_address,
        bridge_3.contract_address
    );
    let l1_strategy_1: EthAddress = 2.try_into().unwrap();
    let l1_strategy_2: EthAddress = 3.try_into().unwrap();
    let l1_strategy_3: EthAddress = 4.try_into().unwrap();

    let performance_fees_strategy_1 = 200000000000000000;
    let min_deposit_1 = 100000000000000000;
    let max_deposit_1 = 10000000000000000000;
    let min_withdraw_1 = 200000000000000000;
    let max_withdraw_1 = 2000000000000000000000000;
    let withdrawal_epoch_delay_1 = 2;
    let dust_limit_1 = 1000000000000000000;
    let name_1 = 10;
    let symbol_1 = 1000;

    start_prank(CheatTarget::One(factory.contract_address), owner);
    let (token_manager_deployed_address, token_deployed_address) = factory
        .deploy_strategy(
            l1_strategy_1,
            token_1.contract_address,
            name_1,
            symbol_1,
            performance_fees_strategy_1,
            min_deposit_1,
            max_deposit_1,
            min_withdraw_1,
            max_withdraw_1,
            withdrawal_epoch_delay_1,
            dust_limit_1
        );
    let (token_manager_deployed_address2, token_deployed_address2) = factory
        .deploy_strategy(
            l1_strategy_2,
            token_2.contract_address,
            name_1,
            symbol_1,
            performance_fees_strategy_1,
            min_deposit_1,
            max_deposit_1,
            min_withdraw_1,
            max_withdraw_1,
            withdrawal_epoch_delay_1,
            dust_limit_1
        );

    let (token_manager_deployed_address3, token_deployed_address3) = factory
        .deploy_strategy(
            l1_strategy_3,
            token_3.contract_address,
            name_1,
            symbol_1,
            performance_fees_strategy_1,
            min_deposit_1,
            max_deposit_1,
            min_withdraw_1,
            max_withdraw_1,
            withdrawal_epoch_delay_1,
            dust_limit_1
        );
    stop_prank(CheatTarget::One(factory.contract_address));
    return (
        token_manager_deployed_address,
        token_deployed_address,
        pooling_manager,
        token_manager_deployed_address2,
        token_deployed_address2,
        token_manager_deployed_address3,
        token_deployed_address3
    );
}

fn transfer_to_users(
    owner: ContractAddress, amount: u256, users: @Array<ContractAddress>, token: ERC20ABIDispatcher
) {
    let mut i = 0;
    let user_array_len = users.len();
    loop {
        if (i == user_array_len) {
            break ();
        }
        if (*users.at(i) != owner) {
            start_prank(CheatTarget::One(token.contract_address), owner);
            token.transfer(*users.at(i), 3000000000000000000);
            stop_prank(CheatTarget::One(token.contract_address));
        }
        i += 1;
    };
}

fn multiple_approve_to_contract(
    amount: u256,
    users: @Array<ContractAddress>,
    token: ERC20ABIDispatcher,
    token_managers: @Array<ITokenManagerDispatcher>
) {
    let mut i = 0;
    let user_array_len = users.len();
    loop {
        if (i == user_array_len) {
            break ();
        }
        let mut j = 0;
        loop {
            if (j == token_managers.len()) {
                break ();
            }
            approve_to_contract(amount, *users.at(i), token, *token_managers.at(j));
            j += 1;
        };
        i += 1;
    };
}

fn approve_to_contract(
    amount: u256,
    user: ContractAddress,
    token: ERC20ABIDispatcher,
    token_manager: ITokenManagerDispatcher
) {
    start_prank(CheatTarget::One(token.contract_address), user);
    token.approve(token_manager.contract_address, amount);
    stop_prank(CheatTarget::One(token.contract_address));
}

fn deposit(
    token_manager_address: ContractAddress,
    token_address: ContractAddress,
    owner: ContractAddress,
    assets: u256
) {
    let receiver = contract_address_const::<24>();

    let token_contract = ERC20ABIDispatcher { contract_address: token_address };
    let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };
    let underlying_token_address = token_manager.underlying();
    let underlying_token = ERC20ABIDispatcher { contract_address: underlying_token_address };

    start_prank(CheatTarget::One(token_manager.contract_address), owner);
    token_manager.deposit(assets, receiver, contract_address_const::<23>());
    let token = token_manager.token();
    assert(token == token_address, 'Wrong token address');
    stop_prank(CheatTarget::One(token_manager.contract_address));
}

fn deposit_and_handle_mass() -> (ContractAddress, ContractAddress, IPoolingManagerDispatcher) {
    let (token_manager_address, token_address, pooling_manager) = deploy_strategy();
    let owner = contract_address_const::<2300>();
    let receiver = contract_address_const::<24>();
    let assets = 200000000000000000;

    let token_contract = ERC20ABIDispatcher { contract_address: token_address };
    let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };
    let underlying_token_address = token_manager.underlying();
    let underlying_token = ERC20ABIDispatcher { contract_address: underlying_token_address };

    start_prank(CheatTarget::One(underlying_token.contract_address), owner);
    underlying_token.approve(token_manager_address, 1000000000000000000002);
    stop_prank(CheatTarget::One(underlying_token.contract_address));

    deposit(token_manager_address, token_address, owner, assets);

    start_prank(CheatTarget::One(token_contract.contract_address), receiver);
    token_contract.approve(token_manager_address, 1000000000000000000002);
    stop_prank(CheatTarget::One(token_contract.contract_address));

    start_prank(CheatTarget::One(token_manager.contract_address), receiver);
    let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };
    token_manager.request_withdrawal(assets);
    stop_prank(CheatTarget::One(token_manager.contract_address));

    let balance = token_contract.balance_of(receiver);
    assert(balance == 0, 'Wrong new token balance');

    start_prank(CheatTarget::One(pooling_manager.contract_address), owner);
    let calldata: Array<StrategyReportL1> = array![];

    pooling_manager.handle_mass_report(calldata.span());
    stop_prank(CheatTarget::One(pooling_manager.contract_address));

    return (token_manager_address, token_address, pooling_manager);
}
