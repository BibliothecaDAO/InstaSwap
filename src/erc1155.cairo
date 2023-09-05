use array::SpanSerde;

const IERC1155_ID: felt252 = 0xdef955e77a50cefb767c39f5e3bacb4d24f75e2de1d930ae214fcd6f7d42f3;
const IERC1155_METADATA_ID: felt252 = 0x3d7b708e1a6bd1a69c8d4deedf7ad6adc6cda9cc81bd97c49dc1c82e172d1fc;
const IERC1155_RECEIVER_ID: felt252 = 0x15e8665b5af20040c3af1670509df02eb916375cdf7d8cbaf7bd553a257515e;
const ON_ERC1155_RECEIVED_SELECTOR: felt252 = 0x1f928a663a481b50693917b04eb6f9e6981e815b79fb9ee963bee52fb9a4042;
const ON_ERC1155_BATCH_RECEIVED_SELECTOR: felt252 = 0xa7aec3d60ba1b10aa9601c01e2b09c82108b607a68612539403b0159cd111c;

#[starknet::interface]
trait IERC1155<TContractState> {
  fn balance_of(self: @TContractState, account: starknet::ContractAddress, id: u256) -> u256;

  fn balance_of_batch(self: @TContractState, accounts: Span<starknet::ContractAddress>, ids: Span<u256>) -> Span<u256>;

  fn is_approved_for_all(
    self: @TContractState,
    account: starknet::ContractAddress,
    operator: starknet::ContractAddress
  ) -> bool;

  fn set_approval_for_all(ref self: TContractState, operator: starknet::ContractAddress, approved: bool);

  fn safe_transfer_from(
    ref self: TContractState,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  );

  fn safe_batch_transfer_from(
    ref self: TContractState,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    ids: Span<u256>,
    amounts: Span<u256>,
    data: Span<felt252>
  );
}

#[starknet::interface]
trait IERC1155CamelOnly<TContractState> {
  fn balanceOf(self: @TContractState, account: starknet::ContractAddress, id: u256) -> u256;

  fn balanceOfBatch(self: @TContractState, accounts: Span<starknet::ContractAddress>, ids: Span<u256>) -> Span<u256>;

  fn isApprovedForAll(
    self: @TContractState,
    account: starknet::ContractAddress,
    operator: starknet::ContractAddress
  ) -> bool;

  fn setApprovalForAll(ref self: TContractState, operator: starknet::ContractAddress, approved: bool);

  fn safeTransferFrom(
    ref self: TContractState,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    id: u256,
    amount: u256,
    data: Span<felt252>
  );

  fn safeBatchTransferFrom(
    ref self: TContractState,
    from: starknet::ContractAddress,
    to: starknet::ContractAddress,
    ids: Span<u256>,
    amounts: Span<u256>,
    data: Span<felt252>
  );
}

use IERC1155CamelOnly as IERC1155Camel;

// IERC1155 Metadata

#[starknet::interface]
trait IERC1155Metadata<TContractState> {
  fn uri(self: @TContractState, token_id: u256) -> Span<felt252>;
}

// ERC1155 Receiver

#[starknet::interface]
trait IERC1155Receiver<TContractState> {
  fn on_erc1155_received(
    ref self: TContractState,
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    id: u256,
    value: u256,
    data: Span<felt252>
  ) -> felt252;

  fn on_erc1155_batch_received(
    ref self: TContractState,
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    ids: Span<u256>,
    values: Span<u256>,
    data: Span<felt252>
  ) -> felt252;
}

#[starknet::interface]
trait IERC1155ReceiverCamel<TContractState> {
  fn onERC1155Received(
    ref self: TContractState,
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    id: u256,
    value: u256,
    data: Span<felt252>
  ) -> felt252;

  fn onERC1155BatchReceived(
    ref self: TContractState,
    operator: starknet::ContractAddress,
    from: starknet::ContractAddress,
    ids: Span<u256>,
    values: Span<u256>,
    data: Span<felt252>
  ) -> felt252;
}
