const SUCCESS: felt252 = 'SUCCESS';
const FAILURE: felt252 = 'FAILURE';

//
// Receiver
//

#[starknet::contract]
mod ERC1155Receiver {
    use array::{SpanTrait, SpanSerde};
    use rules_utils::introspection::interface::ISRC5;

    // locals
    use rules_erc1155::erc1155::interface;

    //
    // Storage
    //

    #[storage]
    struct Storage {}

    //
    // IERC1155 Receiver impl
    //

    #[external(v0)]
    impl ERC1155ReceiverImpl of interface::IERC1155Receiver<ContractState> {
        fn on_erc1155_received(
            ref self: ContractState,
            operator: starknet::ContractAddress,
            from: starknet::ContractAddress,
            id: u256,
            value: u256,
            data: Span<felt252>
        ) -> felt252 {
            if (*data.at(0) == super::SUCCESS) {
                interface::ON_ERC1155_RECEIVED_SELECTOR
            } else {
                0
            }
        }

        fn on_erc1155_batch_received(
            ref self: ContractState,
            operator: starknet::ContractAddress,
            from: starknet::ContractAddress,
            ids: Span<u256>,
            values: Span<u256>,
            data: Span<felt252>
        ) -> felt252 {
            if (*data.at(0) == super::SUCCESS) {
                interface::ON_ERC1155_BATCH_RECEIVED_SELECTOR
            } else {
                0
            }
        }
    }

    //
    // ISRC5
    //

    #[external(v0)]
    impl ISRC5Impl of ISRC5<ContractState> {
        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            interface_id == interface::IERC1155_RECEIVER_ID
        }
    }
}

//
// Receiver Camel
//

#[starknet::contract]
mod ERC1155ReceiverCamel {
    use array::{SpanTrait, SpanSerde};
    use rules_utils::introspection::interface::ISRC5Camel;

    // locals
    use rules_erc1155::erc1155::interface;

    //
    // Storage
    //

    #[storage]
    struct Storage {}

    //
    // IERC1155 Receiver impl
    //

    #[external(v0)]
    impl ERC1155ReceiverImpl of interface::IERC1155ReceiverCamel<ContractState> {
        fn onERC1155Received(
            ref self: ContractState,
            operator: starknet::ContractAddress,
            from: starknet::ContractAddress,
            id: u256,
            value: u256,
            data: Span<felt252>
        ) -> felt252 {
            if (*data.at(0) == super::SUCCESS) {
                interface::ON_ERC1155_RECEIVED_SELECTOR
            } else {
                0
            }
        }

        fn onERC1155BatchReceived(
            ref self: ContractState,
            operator: starknet::ContractAddress,
            from: starknet::ContractAddress,
            ids: Span<u256>,
            values: Span<u256>,
            data: Span<felt252>
        ) -> felt252 {
            if (*data.at(0) == super::SUCCESS) {
                interface::ON_ERC1155_BATCH_RECEIVED_SELECTOR
            } else {
                0
            }
        }
    }

    //
    // ISRC5
    //

    #[external(v0)]
    impl ISRC5CamelImpl of ISRC5Camel<ContractState> {
        fn supportsInterface(self: @ContractState, interfaceId: felt252) -> bool {
            interfaceId == interface::IERC1155_RECEIVER_ID
        }
    }
}

//
// Non receiver
//

#[starknet::contract]
mod ERC1155NonReceiver {
    #[storage]
    struct Storage {}

    #[constructor]
    fn constructor(ref self: ContractState) {}
}
