use starknet::{ContractAddress, ClassHash};

#[starknet::interface]
trait IToken<TContractState> {
    fn mint(ref self: TContractState, recipient: ContractAddress, amount: u256);
    fn burn(ref self: TContractState, acccount: ContractAddress, amount: u256);
}
