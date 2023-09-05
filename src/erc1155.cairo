#[starknet::interface]
trait ERC1155ABI<TContractState> {
  fn uri(self: @TContractState, token_id: u256) -> Span<felt252>;

  fn supports_interface(self: @TContractState, interface_id: felt252) -> bool;

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

    fn mint(
        ref self: TContractState,
        to: starknet::ContractAddress,
        id: u256,
        amount: u256,
        data: Span<felt252>
    );
}