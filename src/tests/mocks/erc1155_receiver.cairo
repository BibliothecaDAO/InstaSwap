use rules_account::introspection::erc165::IERC165;
const SUCCESS: felt252 = 'SUCCESS';
const FAILURE: felt252 = 'FAILURE';

#[starknet::contract]
mod ERC1155Receiver {
  use array::{ SpanTrait, SpanSerde };

  // locals
  use rules_erc1155::erc1155::interface::IERC1155Receiver;
  use rules_erc1155::erc1155::interface::IERC1155_RECEIVER_ID;
  use rules_erc1155::erc1155::interface::ON_ERC1155_RECEIVED_SELECTOR;
  use rules_erc1155::erc1155::interface::ON_ERC1155_BATCH_RECEIVED_SELECTOR;
  use rules_erc1155::introspection::erc165::{ ERC165, IERC165 };
  use rules_erc1155::introspection::erc165::ERC165::HelperTrait;

  //
  // Storage
  //

  #[storage]
  struct Storage { }

  //
  // Constructor
  //

  #[constructor]
  fn constructor(ref self: ContractState) {
    let mut erc165_self = ERC165::unsafe_new_contract_state();

    erc165_self._register_interface(interface_id: IERC1155_RECEIVER_ID);
  }

  //
  // ERC1155 Receiver impl
  //

  #[external(v0)]
  impl ERC1155ReceiverImpl of IERC1155Receiver<ContractState> {
    fn on_erc1155_received(
      ref self: ContractState,
      operator: starknet::ContractAddress,
      from: starknet::ContractAddress,
      id: u256,
      value: u256,
      data: Span<felt252>
    ) -> u32 {
      if (*data.at(0) == super::SUCCESS) {
        ON_ERC1155_RECEIVED_SELECTOR
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
    ) -> u32 {
      if (*data.at(0) == super::SUCCESS) {
        ON_ERC1155_BATCH_RECEIVED_SELECTOR
      } else {
        0
      }
    }
  }

  #[external(v0)]
  fn supports_interface(self: @ContractState, interface_id: u32) -> bool {
    let erc165_self = ERC165::unsafe_new_contract_state();

    erc165_self.supports_interface(:interface_id)
  }
}

#[starknet::contract]
mod ERC1155NonReceiver {
  #[storage]
  struct Storage { }

  #[constructor]
  fn constructor(ref self: ContractState) {}
}
