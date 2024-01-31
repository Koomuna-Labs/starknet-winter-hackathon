use starknet::{ContractAddress, ClassHash, eth_address::EthAddress};


#[derive(Copy, Drop, Serde, starknet::Store)]
struct WithdrawalInfo {
    epoch: u256,
    shares: u256,
    claimed: bool
}

#[derive(Copy, Drop, Serde)]
struct StrategyReportL2 {
    l1_strategy: EthAddress,
    action_id: u256,
    amount: u256,
    new_share_price: u256
}


#[starknet::interface]
trait ITokenManager<TContractState> {
    fn pooling_manager(self: @TContractState) -> ContractAddress;
    fn l1_strategy(self: @TContractState) -> EthAddress;
    fn underlying(self: @TContractState) -> ContractAddress;
    fn token(self: @TContractState) -> ContractAddress;
    fn performance_fees(self: @TContractState) -> u256;
    fn deposit_limit_low(self: @TContractState) -> u256;
    fn deposit_limit_high(self: @TContractState) -> u256;
    fn withdrawal_limit_low(self: @TContractState) -> u256;
    fn withdrawal_limit_high(self: @TContractState) -> u256;
    fn withdrawal_epoch_delay(self: @TContractState) -> u256;
    fn handled_epoch_withdrawal_len(self: @TContractState) -> u256;
    fn epoch(self: @TContractState) -> u256;
    fn l1_net_asset_value(self: @TContractState) -> u256;
    fn underlying_transit(self: @TContractState) -> u256;
    fn buffer(self: @TContractState) -> u256;
    fn withdrawal_info(self: @TContractState, user: ContractAddress, id: u256) -> WithdrawalInfo;
    fn user_withdrawal_len(self: @TContractState, user: ContractAddress) -> u256;
    fn dust_limit(self: @TContractState) -> u256;
    fn total_assets(self: @TContractState) -> u256;
    fn total_underlying_due(self: @TContractState) -> u256;
    fn withdrawal_exchange_rate(self: @TContractState, epoch: u256) -> u256;
    fn withdrawal_pool(self: @TContractState, epoch: u256) -> u256;
    fn withdrawal_share(self: @TContractState, epoch: u256) -> u256;


    fn initialiser(ref self: TContractState, token: ContractAddress);

    fn set_performance_fees(ref self: TContractState, new_performance_fees: u256);

    fn set_deposit_limit(
        ref self: TContractState, new_deposit_limit_low: u256, new_deposit_limit_high: u256
    );

    fn set_withdrawal_limit(
        ref self: TContractState, new_withdrawal_limit_low: u256, new_withdrawal_limit_high: u256
    );

    fn set_withdrawal_epoch_delay(ref self: TContractState, new_withdrawal_epoch_delay: u256);

    fn set_dust_limit(ref self: TContractState, new_dust_limit: u256);

    fn deposit(
        ref self: TContractState, assets: u256, receiver: ContractAddress, referal: ContractAddress
    );

    fn request_withdrawal(ref self: TContractState, shares: u256);

    fn claim_withdrawal(ref self: TContractState, id: u256);

    fn handle_report(
        ref self: TContractState, l1_net_asset_value: u256, underlying_bridged_amount: u256
    ) -> StrategyReportL2;
}
