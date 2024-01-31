#[cfg(test)]
mod testTokenManager {
    use core::array::ArrayTrait;
    use core::debug::PrintTrait;
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

    // Utils peripheric contracts
    use nimbora_yields::token_bridge::token_bridge::{TokenBridge};
    use nimbora_yields::token_bridge::token_mock::{TokenMock};
    use nimbora_yields::token_bridge::interface::{
        ITokenBridgeDispatcher, IMintableTokenDispatcher, IMintableTokenDispatcherTrait
    };

    use openzeppelin::{
        token::erc20::interface::{IERC20, ERC20ABIDispatcher, ERC20ABIDispatcherTrait},
        access::accesscontrol::{
            AccessControlComponent,
            interface::{IAccessControlDispatcher, IAccessControlDispatcherTrait}
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
        declare, ContractClassTrait, start_prank, CheatTarget, ContractClass, stop_prank,
        start_warp, stop_warp, L1Handler, get_class_hash, spy_events, SpyOn, EventSpy, EventFetcher,
        event_name_hash, Event
    };

    use nimbora_yields::tests::test_utils::{
        deploy_tokens, deploy_token_manager, deploy_strategy, deploy_two_strategy,
        deploy_three_strategy, approve_to_contract, multiple_approve_to_contract, transfer_to_users,
        deposit, deposit_and_handle_mass
    };

    #[test]
    #[should_panic(expected: ('Invalid caller',))]
    fn upgrade_token_manager_wrong_caller() {
        let token_manager = deploy_token_manager();

        let mock_contract = declare('MockTokenManager');
        let old_class_hash = get_class_hash(token_manager.contract_address);
        IUpgradeableDispatcher { contract_address: token_manager.contract_address }
            .upgrade(mock_contract.class_hash);
    }

    #[test]
    #[should_panic(expected: ('Class hash cannot be zero',))]
    fn upgrade_token_manager_zero_class_hash() {
        let token_manager = deploy_token_manager();
        let owner = contract_address_const::<2300>();

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        let old_class_hash = get_class_hash(token_manager.contract_address);
        IUpgradeableDispatcher { contract_address: token_manager.contract_address }
            .upgrade(Zeroable::zero());
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Invalid caller',))]
    fn token_manager_set_performance_fees_with_unregister_strategy() {
        let token_manager = deploy_token_manager();
        let owner = contract_address_const::<2300>();

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        token_manager.set_performance_fees(1000000000000000);
        assert(token_manager.performance_fees() == 1000000000000000, 'Wrong performance fees');
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    fn token_manager_set_performance() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        token_manager.set_performance_fees(1000000000000000);
        assert(token_manager.performance_fees() == 1000000000000000, 'Wrong performance fees');
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Fee amount too high',))]
    fn token_manager_set_performance_fees_too_high() {
        let token_manager = deploy_token_manager();
        let owner = contract_address_const::<2300>();

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        token_manager.set_performance_fees(1000000000000000000);
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Invalid caller',))]
    fn token_manager_set_performance_fees_wrong_caller() {
        let token_manager = deploy_token_manager();
        let owner = contract_address_const::<2300>();

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        token_manager.set_performance_fees(10000000000000000);
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    fn token_manager_set_deposit_limit() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        token_manager.set_deposit_limit(1000000000, 2000000000);
        let low_limit = token_manager.deposit_limit_low();
        let high_limit = token_manager.deposit_limit_high();

        assert(low_limit == 1000000000, 'Wrong low deposit limit');
        assert(high_limit == 2000000000, 'Wrong high deposit limit');
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Invalid limit',))]
    fn token_manager_set_deposit_limit_low_greater_high() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        token_manager.set_deposit_limit(1000000000000000, 12);
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Amount nul',))]
    fn token_manager_set_deposit_limit_zero_low() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        token_manager.set_deposit_limit(0, 12);
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    fn token_manager_set_withdrawal_limit() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        token_manager.set_withdrawal_limit(1000000000, 2000000000);
        let low_limit = token_manager.withdrawal_limit_low();
        let high_limit = token_manager.withdrawal_limit_high();

        assert(low_limit == 1000000000, 'Wrong low withdrawal limit');
        assert(high_limit == 2000000000, 'Wrong high withdrawal limit');
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Invalid limit',))]
    fn token_manager_set_withdrawal_limit_low_greater_high() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        token_manager.set_withdrawal_limit(1000000000000000, 12);
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Amount nul',))]
    fn token_manager_set_withdrawal_limit_zero_low() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        token_manager.set_withdrawal_limit(0, 12);
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }


    #[test]
    fn token_manager_set_withdrawal_epoch_delay() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        token_manager.set_withdrawal_epoch_delay(1000000000);
        let epoch_delay = token_manager.withdrawal_epoch_delay();

        assert(epoch_delay == 1000000000, 'Wrong epoch delay');
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Invalid caller',))]
    fn token_manager_set_withdrawal_epoch_delay_wrong_caller() {
        let token_manager = deploy_token_manager();
        let owner = contract_address_const::<2300>();

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        token_manager.set_withdrawal_epoch_delay(10000000000000);
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Amount nul',))]
    fn token_manager_set_withdrawal_epoch_delay_zero_epoch() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        token_manager.set_withdrawal_epoch_delay(0);
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }


    #[test]
    fn token_manager_set_dust_limit() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        token_manager.set_dust_limit(1000000000);
        let dust_limit = token_manager.dust_limit();

        assert(dust_limit == 1000000000, 'Wrong dust limit');
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Invalid caller',))]
    fn token_manager_set_dust_limit_wrong_caller() {
        let token_manager = deploy_token_manager();
        let owner = contract_address_const::<2300>();

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        token_manager.set_dust_limit(10000000000000);
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    #[should_panic(expected: ('Amount nul',))]
    fn token_manager_set_dust_limit_zero() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        token_manager.set_dust_limit(0);
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    fn get_total_assets_should_be_zero() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        let result = token_manager.total_assets();
        assert(result == 0, 'Total asset is not 0');
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    fn get_total_underlying_dueshould_be_zero() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        let result = token_manager.total_underlying_due();
        assert(result == 0, 'Total underlying due is not 0');
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    fn test_deposit() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();
        let receiver = contract_address_const::<24>();
        let assets = 100000000000000002;

        let token_contract = ERC20ABIDispatcher { contract_address: token_address };
        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };
        let underlying_token_address = token_manager.underlying();
        let underlying_token = ERC20ABIDispatcher { contract_address: underlying_token_address };

        start_prank(CheatTarget::One(underlying_token.contract_address), owner);
        underlying_token.approve(token_manager_address, 1000000000000000000002);
        stop_prank(CheatTarget::One(underlying_token.contract_address));

        deposit(token_manager_address, token_address, owner, assets);

        let balance = underlying_token.balance_of(token_manager_address);
        assert(balance == assets, 'Wrong underlying balance');

        let balance = token_contract.balance_of(receiver);
        assert(balance == assets, 'Wrong token balance');
    }

    #[test]
    #[should_panic(expected: ('Low limit reacher',))]
    fn test_deposit_low_limit_reached() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();
        let receiver = contract_address_const::<24>();
        let assets = 10000000000000000;

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        let result = token_manager.deposit(assets, receiver, contract_address_const::<23>());
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    #[should_panic(expected: ('High limit reacher',))]
    fn test_deposit_high_limit_reached() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();
        let receiver = contract_address_const::<24>();
        let assets = 10000000000000000001;

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), owner);
        let result = token_manager.deposit(assets, contract_address_const::<23>(), receiver);
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    fn test_request_withdrawal_full_shares() {
        let (token_manager_address, token_address, _) = deploy_strategy();
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

        let balance = underlying_token.balance_of(token_manager_address);
        assert(balance == assets, 'Wrong underlying balance');

        let balance = token_contract.balance_of(receiver);
        assert(balance == assets, 'Wrong token balance');

        start_prank(CheatTarget::One(token_contract.contract_address), receiver);
        token_contract.approve(token_manager_address, 1000000000000000000002);
        stop_prank(CheatTarget::One(token_contract.contract_address));

        start_prank(CheatTarget::One(token_manager.contract_address), receiver);
        token_manager.request_withdrawal(assets);
        stop_prank(CheatTarget::One(token_manager.contract_address));

        let balance = token_contract.balance_of(receiver);
        assert(balance == 0, 'Wrong new token balance');
    }

    #[test]
    #[should_panic(expected: ('Low limit reacher',))]
    fn test_request_withdrawal_low_limit_reacher() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();
        let receiver = contract_address_const::<24>();
        let assets = 100000000000000000;

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), receiver);
        token_manager.request_withdrawal(assets);
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    fn test_request_withdrawal_partial_shares() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();
        let receiver = contract_address_const::<24>();
        let assets = 300000000000000000;

        let token_contract = ERC20ABIDispatcher { contract_address: token_address };
        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };
        let underlying_token_address = token_manager.underlying();
        let underlying_token = ERC20ABIDispatcher { contract_address: underlying_token_address };

        start_prank(CheatTarget::One(underlying_token.contract_address), owner);
        underlying_token.approve(token_manager_address, 1000000000000000000002);
        stop_prank(CheatTarget::One(underlying_token.contract_address));

        deposit(token_manager_address, token_address, owner, assets);

        let balance = underlying_token.balance_of(token_manager_address);
        assert(balance == assets, 'Wrong underlying balance');

        let balance = token_contract.balance_of(receiver);
        assert(balance == assets, 'Wrong token balance');

        start_prank(CheatTarget::One(token_contract.contract_address), receiver);
        token_contract.approve(token_manager_address, 1000000000000000000002);
        stop_prank(CheatTarget::One(token_contract.contract_address));

        start_prank(CheatTarget::One(token_manager.contract_address), receiver);
        token_manager.request_withdrawal(assets - 100000000000000000);
        stop_prank(CheatTarget::One(token_manager.contract_address));

        let balance = token_contract.balance_of(receiver);
        assert(balance == 100000000000000000, 'Wrong new token balance');
    }

    #[test]
    #[should_panic(expected: ('High limit reacher',))]
    fn test_request_withdrawal_high_limit_reacher() {
        let (token_manager_address, token_address, _) = deploy_strategy();
        let owner = contract_address_const::<2300>();
        let receiver = contract_address_const::<24>();
        let assets = 20000000000000000000000001;

        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };

        start_prank(CheatTarget::One(token_manager.contract_address), receiver);
        token_manager.request_withdrawal(assets);
        stop_prank(CheatTarget::One(token_manager.contract_address));
    }

    #[test]
    fn test_handle_report() {
        let (token_manager_address, token_address, pooling_manager) = deploy_strategy();
        let owner = contract_address_const::<2300>();
        let receiver = contract_address_const::<24>();
        let l1_pooling_manager: EthAddress = 100.try_into().unwrap();
        let assets = 200000000000000000;

        let token_contract = ERC20ABIDispatcher { contract_address: token_address };
        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };
        let underlying_token_address = token_manager.underlying();
        let underlying_token = ERC20ABIDispatcher { contract_address: underlying_token_address };

        start_prank(CheatTarget::One(underlying_token.contract_address), owner);
        underlying_token.approve(token_manager_address, 1000000000000000000002);
        stop_prank(CheatTarget::One(underlying_token.contract_address));
        deposit(token_manager_address, token_address, owner, assets);

        let balance = underlying_token.balance_of(token_manager_address);
        assert(balance == assets, 'Wrong underlying balance');

        let balance = token_contract.balance_of(receiver);
        assert(balance == assets, 'Wrong token balance');

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
    }

    #[test]
    fn test_handle_report_2_deposit() {
        let (token_manager_address, token_address, pooling_manager) = deploy_strategy();
        let owner = contract_address_const::<2300>();
        let user2 = contract_address_const::<2301>();

        let receiver = contract_address_const::<24>();
        let l1_pooling_manager: EthAddress = 100.try_into().unwrap();
        let assets = 200000000000000000;
        let l1_strategy: EthAddress = 2.try_into().unwrap();

        let token_contract = ERC20ABIDispatcher { contract_address: token_address };
        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };
        let underlying_token_address = token_manager.underlying();
        let underlying_token = ERC20ABIDispatcher { contract_address: underlying_token_address };

        start_prank(CheatTarget::One(underlying_token.contract_address), owner);
        underlying_token.approve(token_manager_address, 1000000000000000000002);
        underlying_token.transfer(user2, 300000000000000000);
        stop_prank(CheatTarget::One(underlying_token.contract_address));

        start_prank(CheatTarget::One(underlying_token.contract_address), user2);
        underlying_token.approve(token_manager_address, 1000000000000000000002);
        stop_prank(CheatTarget::One(underlying_token.contract_address));

        deposit(token_manager_address, token_address, owner, assets);
        deposit(token_manager_address, token_address, user2, assets);

        start_prank(CheatTarget::One(token_contract.contract_address), receiver);
        token_contract.approve(token_manager_address, 1000000000000000000002);
        stop_prank(CheatTarget::One(token_contract.contract_address));

        start_prank(CheatTarget::One(token_manager.contract_address), receiver);
        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };
        token_manager.request_withdrawal(assets);
        stop_prank(CheatTarget::One(token_manager.contract_address));

        let balance = token_contract.balance_of(receiver);
        assert(balance == 200000000000000000, 'Wrong new token balance');

        start_prank(CheatTarget::One(pooling_manager.contract_address), owner);
        let calldata: Array<StrategyReportL1> = array![];

        pooling_manager.handle_mass_report(calldata.span());
        stop_prank(CheatTarget::One(pooling_manager.contract_address));
    }

    #[test]
    fn test_handle_report_5_deposit() {
        let (token_manager_address, token_address, pooling_manager) = deploy_strategy();
        let owner = contract_address_const::<2300>();
        let user2 = contract_address_const::<2301>();
        let user3 = contract_address_const::<2302>();
        let user4 = contract_address_const::<2303>();
        let user5 = contract_address_const::<2304>();

        let receiver = contract_address_const::<24>();
        let l1_pooling_manager: EthAddress = 100.try_into().unwrap();
        let assets = 200000000000000000;
        let l1_strategy: EthAddress = 2.try_into().unwrap();

        let token_contract = ERC20ABIDispatcher { contract_address: token_address };
        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };
        let underlying_token_address = token_manager.underlying();
        let underlying_token = ERC20ABIDispatcher { contract_address: underlying_token_address };

        start_prank(CheatTarget::One(underlying_token.contract_address), owner);
        underlying_token.approve(token_manager_address, 1000000000000000000002);
        underlying_token.transfer(user2, 300000000000000000);
        underlying_token.transfer(user3, 300000000000000000);
        underlying_token.transfer(user4, 300000000000000000);
        underlying_token.transfer(user5, 300000000000000000);
        stop_prank(CheatTarget::One(underlying_token.contract_address));

        start_prank(CheatTarget::One(underlying_token.contract_address), user2);
        underlying_token.approve(token_manager_address, 1000000000000000000002);
        stop_prank(CheatTarget::One(underlying_token.contract_address));

        start_prank(CheatTarget::One(underlying_token.contract_address), user3);
        underlying_token.approve(token_manager_address, 1000000000000000000002);
        stop_prank(CheatTarget::One(underlying_token.contract_address));

        start_prank(CheatTarget::One(underlying_token.contract_address), user4);
        underlying_token.approve(token_manager_address, 1000000000000000000002);
        stop_prank(CheatTarget::One(underlying_token.contract_address));

        start_prank(CheatTarget::One(underlying_token.contract_address), user5);
        underlying_token.approve(token_manager_address, 1000000000000000000002);
        stop_prank(CheatTarget::One(underlying_token.contract_address));

        deposit(token_manager_address, token_address, owner, assets);
        deposit(token_manager_address, token_address, user2, assets);
        deposit(token_manager_address, token_address, user3, assets + 10000000000000000);
        deposit(token_manager_address, token_address, user4, assets + 15000000000000000);
        deposit(token_manager_address, token_address, user5, assets);

        let balance = underlying_token.balance_of(token_manager_address);
        assert(balance == ((assets * 5) + 25000000000000000), 'Wrong underlying balance');

        let balance = token_contract.balance_of(receiver);
        assert(balance == ((assets * 5) + 25000000000000000), 'Wrong token balance');

        start_prank(CheatTarget::One(token_contract.contract_address), receiver);
        token_contract.approve(token_manager_address, 1000000000000000000002);
        stop_prank(CheatTarget::One(token_contract.contract_address));

        start_prank(CheatTarget::One(token_manager.contract_address), receiver);
        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };
        token_manager.request_withdrawal(assets * 5);
        stop_prank(CheatTarget::One(token_manager.contract_address));

        let balance = token_contract.balance_of(receiver);
        assert(balance == 25000000000000000, 'Wrong new token balance');

        start_prank(CheatTarget::One(pooling_manager.contract_address), owner);
        let calldata: Array<StrategyReportL1> = array![];

        pooling_manager.handle_mass_report(calldata.span());
        stop_prank(CheatTarget::One(pooling_manager.contract_address));
    }

    #[test]
    fn test_handle_report_multiple_strategy() {
        let (
            token_manager_address,
            token_address,
            pooling_manager,
            token_manager_address2,
            token_address2
        ) =
            deploy_two_strategy();
        let owner = contract_address_const::<2300>();
        let receiver = contract_address_const::<24>();
        let l1_pooling_manager: EthAddress = 100.try_into().unwrap();
        let assets = 200000000000000000;

        let token_contract = ERC20ABIDispatcher { contract_address: token_address };
        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };
        let token_contract2 = ERC20ABIDispatcher { contract_address: token_address2 };
        let token_manager2 = ITokenManagerDispatcher { contract_address: token_manager_address2 };
        let underlying_token_address = token_manager.underlying();
        let underlying_token = ERC20ABIDispatcher { contract_address: underlying_token_address };
        let underlying_token_address2 = token_manager2.underlying();
        let underlying_token2 = ERC20ABIDispatcher { contract_address: underlying_token_address2 };

        start_prank(CheatTarget::One(underlying_token.contract_address), owner);
        underlying_token.approve(token_manager_address, 1000000000000000000002);
        stop_prank(CheatTarget::One(underlying_token.contract_address));

        start_prank(CheatTarget::One(underlying_token2.contract_address), owner);
        underlying_token2.approve(token_manager_address2, 1000000000000000000002);
        stop_prank(CheatTarget::One(underlying_token2.contract_address));

        deposit(token_manager_address, token_address, owner, assets);
        deposit(token_manager_address2, token_address2, owner, assets + 10000000);

        let balance = underlying_token.balance_of(token_manager_address);
        assert(balance == assets, 'Wrong underlying balance');

        let balance = token_contract.balance_of(receiver);
        assert(balance == assets, 'Wrong token balance');

        let balance = underlying_token2.balance_of(token_manager_address2);
        assert(balance == (assets + 10000000), 'Wrong underlying balance');

        let balance = token_contract2.balance_of(receiver);
        assert(balance == (assets + 10000000), 'Wrong token balance');

        start_prank(CheatTarget::One(token_contract.contract_address), receiver);
        token_contract.approve(token_manager_address, 1000000000000000000002);
        stop_prank(CheatTarget::One(token_contract.contract_address));

        start_prank(CheatTarget::One(token_contract2.contract_address), receiver);
        token_contract2.approve(token_manager_address2, 1000000000000000000002);
        stop_prank(CheatTarget::One(token_contract2.contract_address));

        start_prank(CheatTarget::One(token_manager.contract_address), receiver);
        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };
        token_manager.request_withdrawal(assets);
        stop_prank(CheatTarget::One(token_manager.contract_address));

        start_prank(CheatTarget::One(token_manager2.contract_address), receiver);
        let token_manager2 = ITokenManagerDispatcher { contract_address: token_manager_address2 };
        token_manager2.request_withdrawal(assets);
        stop_prank(CheatTarget::One(token_manager2.contract_address));

        let balance = token_contract.balance_of(receiver);
        assert(balance == 0, 'Wrong new token balance');

        let balance = token_contract2.balance_of(receiver);
        assert(balance == 10000000, 'Wrong new token balance');

        start_prank(CheatTarget::One(pooling_manager.contract_address), owner);
        let calldata: Array<StrategyReportL1> = array![];

        pooling_manager.handle_mass_report(calldata.span());
        stop_prank(CheatTarget::One(pooling_manager.contract_address));
    }

    #[test]
    fn test_handle_report_5_deposit_3_strategy() {
        let (
            token_manager_address,
            token_address,
            pooling_manager,
            token_manager_address2,
            token_address2,
            token_manager_address3,
            token_address3
        ) =
            deploy_three_strategy();

        let owner = contract_address_const::<2300>();
        let user2 = contract_address_const::<2301>();
        let user3 = contract_address_const::<2302>();
        let user4 = contract_address_const::<2303>();
        let user5 = contract_address_const::<2304>();

        let receiver = contract_address_const::<24>();
        let l1_pooling_manager: EthAddress = 100.try_into().unwrap();
        let assets = 200000000000000000;

        let token_contract = ERC20ABIDispatcher { contract_address: token_address };
        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };
        let token_contract2 = ERC20ABIDispatcher { contract_address: token_address2 };
        let token_manager2 = ITokenManagerDispatcher { contract_address: token_manager_address2 };
        let token_contract3 = ERC20ABIDispatcher { contract_address: token_address3 };
        let token_manager3 = ITokenManagerDispatcher { contract_address: token_manager_address3 };
        let underlying_token_address = token_manager.underlying();
        let underlying_token = ERC20ABIDispatcher { contract_address: underlying_token_address };
        let underlying_token_address2 = token_manager2.underlying();
        let underlying_token2 = ERC20ABIDispatcher { contract_address: underlying_token_address2 };
        let underlying_token_address3 = token_manager3.underlying();
        let underlying_token3 = ERC20ABIDispatcher { contract_address: underlying_token_address3 };

        let user_array = @array![owner, user2, user3, user4, user5];
        let token_manager_array = @array![token_manager, token_manager2, token_manager3];
        let token_array = @array![token_contract, token_contract2, token_contract3];

        transfer_to_users(owner, 3000000000000000000, user_array, underlying_token);
        transfer_to_users(owner, 3000000000000000000, user_array, underlying_token2);
        transfer_to_users(owner, 3000000000000000000, user_array, underlying_token3);

        multiple_approve_to_contract(
            1000000000000000000002, user_array, underlying_token, token_manager_array
        );
        multiple_approve_to_contract(
            1000000000000000000002, user_array, underlying_token2, token_manager_array
        );
        multiple_approve_to_contract(
            1000000000000000000002, user_array, underlying_token3, token_manager_array
        );

        // Deposite to token_manager
        let mut i = 0;
        loop {
            if (i == user_array.len()) {
                break ();
            }
            let mut j = 0;
            let user = *user_array.at(i);
            loop {
                if (j == token_manager_array.len()) {
                    break ();
                }
                let token_manager_contract = *token_manager_array.at(j);
                start_prank(CheatTarget::One(token_manager_contract.contract_address), user);
                if (user == user3) {
                    token_manager_contract
                        .deposit(
                            assets + 10000000000000000, receiver, contract_address_const::<23>()
                        );
                } else if (user == user4) {
                    token_manager_contract
                        .deposit(
                            assets + 15000000000000000, receiver, contract_address_const::<23>()
                        );
                } else {
                    token_manager_contract
                        .deposit(assets, receiver, contract_address_const::<23>());
                }
                stop_prank(CheatTarget::One(token_manager_contract.contract_address));
                j += 1;
            };
            i += 1;
        };

        let balance = underlying_token.balance_of(token_manager_address);
        assert(balance == ((assets * 5) + 25000000000000000), 'Wrong underlying balance');

        let balance = token_contract.balance_of(receiver);
        assert(balance == ((assets * 5) + 25000000000000000), 'Wrong token balance');

        let balance = underlying_token2.balance_of(token_manager_address2);
        assert(balance == ((assets * 5) + 25000000000000000), 'Wrong underlying balance');

        let balance = token_contract2.balance_of(receiver);
        assert(balance == ((assets * 5) + 25000000000000000), 'Wrong token balance');

        let balance = underlying_token3.balance_of(token_manager_address3);
        assert(balance == ((assets * 5) + 25000000000000000), 'Wrong underlying balance');

        let balance = token_contract3.balance_of(receiver);
        assert(balance == ((assets * 5) + 25000000000000000), 'Wrong token balance');

        // Approve receiver for all token contract
        approve_to_contract(1000000000000000000002, receiver, token_contract, token_manager);
        approve_to_contract(1000000000000000000002, receiver, token_contract2, token_manager2);
        approve_to_contract(1000000000000000000002, receiver, token_contract3, token_manager3);

        // Request Withdrawal for token_manager
        start_prank(CheatTarget::One(token_manager.contract_address), receiver);
        token_manager.request_withdrawal(assets * 5);
        stop_prank(CheatTarget::One(token_manager.contract_address));

        let balance = token_contract.balance_of(receiver);
        assert(balance == 25000000000000000, 'Wrong new token balance');

        // Request Withdrawal for token_manager2
        start_prank(CheatTarget::One(token_manager2.contract_address), receiver);
        token_manager2.request_withdrawal(assets * 5);
        stop_prank(CheatTarget::One(token_manager2.contract_address));

        let balance = token_contract2.balance_of(receiver);
        assert(balance == 25000000000000000, 'Wrong new token balance');

        // Request Withdrawal for token_manager3
        start_prank(CheatTarget::One(token_manager3.contract_address), receiver);
        token_manager3.request_withdrawal(assets * 5);
        stop_prank(CheatTarget::One(token_manager3.contract_address));

        let balance = token_contract3.balance_of(receiver);
        assert(balance == 25000000000000000, 'Wrong new token balance');

        start_prank(CheatTarget::One(pooling_manager.contract_address), owner);
        let calldata: Array<StrategyReportL1> = array![];

        pooling_manager.handle_mass_report(calldata.span());
        stop_prank(CheatTarget::One(pooling_manager.contract_address));
    }


    #[test]
    fn test_l1_handler() {
        let (token_manager_address, token_address, pooling_manager) = deposit_and_handle_mass();

        let owner = contract_address_const::<2300>();
        let receiver = contract_address_const::<24>();
        let l1_pooling_manager: EthAddress = 100.try_into().unwrap();
        let assets = 200000000000000000;

        let token_contract = ERC20ABIDispatcher { contract_address: token_address };
        let token_manager = ITokenManagerDispatcher { contract_address: token_manager_address };
        let underlying_token_address = token_manager.underlying();
        let underlying_token = ERC20ABIDispatcher { contract_address: underlying_token_address };

        let mut spy = spy_events(SpyOn::One(pooling_manager.contract_address));
        spy.fetch_events();

        spy.events.len().print();
    }
}
