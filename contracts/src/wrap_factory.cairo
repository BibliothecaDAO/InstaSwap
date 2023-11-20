
#[starknet::contract]
mod WrapFactory {
    use openzeppelin::token::erc20::erc20::ERC20;
    use starknet::ContractAddress;
    use starknet::{ get_caller_address, get_contract_address};
    use zeroable::Zeroable;
    use instaswap::erc1155::{IERC1155, IERC1155Dispatcher, IERC1155DispatcherTrait};
    use starknet::class_hash::ClassHash;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CreateWrapAddress: CreateWrapAddress,
    }

    #[derive(Drop, starknet::Event)]
    struct CreateWrapAddress {
        erc1155_address: ContractAddress,
        token_id: u256,
        wrap_address: ContractAddress,
    }

    #[storage]
    struct Storage {
        map: LegacyMap::<(ContractAddress, u256), ContractAddress>, // map of (erc1155_address, token_id) to wrap_address
        wrap_hash: felt252, // hash of Wrap class
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        wrap_hash_: felt252,
    ) {
        self.wrap_hash.write(wrap_hash_);
    }

    #[external(v0)]
    #[generate_trait]
    impl WrapFactoryInterfaceImpl of WrapFactoryInterface {
        fn create_wrap_address(ref self: ContractState, erc1155_address: ContractAddress, token_id: u256, name: felt252, symbol: felt252) {
            let wrap_address = self.map.read((erc1155_address, token_id));
            let wrap_hash = self.wrap_hash.read();
            assert(wrap_address.is_zero(), 'Already wrapped');
            let mut calldata = Default::default();
            erc1155_address.serialize(ref calldata);
            token_id.serialize(ref calldata);
            name.serialize(ref calldata);
            symbol.serialize(ref calldata);
            let (address, _) = starknet::deploy_syscall(wrap_hash.try_into().unwrap(), 0, calldata.span(), false)
                .unwrap();
            // emit event
            self
                .emit(
                    Event::CreateWrapAddress(
                        CreateWrapAddress {
                            erc1155_address: erc1155_address,
                            token_id: token_id,
                            wrap_address: address,
                        }
                    )
                );
            self.map.write((erc1155_address, token_id), address);

        }

        fn get_wrap_address(self: @ContractState, erc1155_address: ContractAddress, token_id: u256) -> ContractAddress {
            let wrap_address = self.map.read((erc1155_address, token_id));
            assert(!wrap_address.is_zero(), 'Not wrapped');
            wrap_address
        }

    }

}