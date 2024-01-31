#[starknet::contract]
mod TokenMock {
    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::upgrades::UpgradeableComponent;
    use starknet::{ContractAddress, ClassHash};
    use nimbora_yields::token_bridge::interface::{IMintableToken};

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);


    impl InternalUpgradeableImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl ERC20Impl = ERC20Component::ERC20Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20CamelOnlyImpl = ERC20Component::ERC20CamelOnlyImpl<ContractState>;
    #[abi(embed_v0)]
    impl ERC20MetadataImpl = ERC20Component::ERC20MetadataImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_supply: u256, recipient: ContractAddress) {
        let name = 'MyToken';
        let symbol = 'MTK';
        self.erc20.initializer(name, symbol);
        self.erc20._mint(recipient, initial_supply);
    }

    /// @notice Upgrade contract
    /// @param New contract class hash
    #[external(v0)]
    fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
        self.upgradeable._upgrade(new_class_hash);
    }

    #[external(v0)]
    impl MintableToken of IMintableToken<ContractState> {
        fn permissionedMint(ref self: ContractState, account: ContractAddress, amount: u256) {
            self.erc20._mint(account, amount);
        }

        fn permissionedBurn(ref self: ContractState, account: ContractAddress, amount: u256) {
            self.erc20._burn(account, amount);
        }
    }
}
