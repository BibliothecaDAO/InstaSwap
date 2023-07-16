use core::serde::Serde;
use clone::Clone;
use starknet::testing;
use array::{ ArrayTrait, SpanTrait, SpanCopy, SpanSerde };
use traits::Into;
use zeroable::Zeroable;
use integer::u256_from_felt252;

// locals
use rules_erc1155::introspection::erc165::IERC165;
use rules_erc1155::introspection::erc165;
use rules_erc1155::erc1155;
use rules_erc1155::erc1155::{ ERC1155, ERC1155ABIDispatcher, ERC1155ABIDispatcherTrait };
use rules_erc1155::erc1155::interface::IERC1155;
use super::utils;
use rules_utils::utils::partial_eq::SpanPartialEq;
use super::mocks::account::Account;
use super::mocks::erc1155_receiver::{ ERC1155Receiver, ERC1155NonReceiver, SUCCESS, FAILURE };
use rules_erc1155::erc1155::erc1155::ERC1155::{ ContractState as ERC1155ContractState, HelperTrait };

fn URI() -> Span<felt252> {
  let mut uri = ArrayTrait::new();

  uri.append(111);
  uri.append(222);
  uri.append(333);

  uri.span()
}

// TOKEN ID

fn TOKEN_ID_1() -> u256 {
  'token id 1'.into()
}

fn TOKEN_ID_2() -> u256 {
  'token id 2'.into()
}

fn TOKEN_ID_3() -> u256 {
  'token id 3'.into()
}

fn TOKEN_ID() -> u256 {
  TOKEN_ID_1() + TOKEN_ID_2() + TOKEN_ID_3()
}

fn TOKEN_IDS() -> Span<u256> {
  let mut ids = ArrayTrait::<u256>::new();
  ids.append(TOKEN_ID_1());
  ids.append(TOKEN_ID_2());
  ids.append(TOKEN_ID_3());

  ids.span()
}

// AMOUNT

fn AMOUNT_1() -> u256 {
  'amount 1'.into()
}

fn AMOUNT_2() -> u256 {
  'amount 2'.into()
}

fn AMOUNT_3() -> u256 {
  'amount 3'.into()
}

fn AMOUNT() -> u256 {
  AMOUNT_1() + AMOUNT_2() + AMOUNT_3()
}

fn AMOUNTS() -> Span<u256> {
  let mut amounts = ArrayTrait::<u256>::new();
  amounts.append(AMOUNT_1());
  amounts.append(AMOUNT_2());
  amounts.append(AMOUNT_3());

  amounts.span()
}

// HOLDERS

fn ZERO() -> starknet::ContractAddress {
  Zeroable::zero()
}

fn OWNER() -> starknet::ContractAddress {
  starknet::contract_address_const::<10>()
}

fn RECIPIENT() -> starknet::ContractAddress {
  starknet::contract_address_const::<20>()
}

fn SPENDER() -> starknet::ContractAddress {
  starknet::contract_address_const::<30>()
}

fn OPERATOR() -> starknet::ContractAddress {
  starknet::contract_address_const::<40>()
}

fn OTHER() -> starknet::ContractAddress {
  starknet::contract_address_const::<50>()
}

// DATA

fn DATA(success: bool) -> Span<felt252> {
  let mut data = ArrayTrait::new();
  if success {
    data.append(SUCCESS);
  } else {
    data.append(FAILURE);
  }
  data.span()
}

//
// Setup
//

fn setup() -> ERC1155ContractState {
  let owner = setup_receiver();
  setup_with_owner(owner)
}

fn setup_with_owner(owner: starknet::ContractAddress) -> ERC1155ContractState {
  let mut erc1155 = ERC1155::contract_state_for_testing();

  erc1155.initializer(URI());
  erc1155._mint(to: owner, id: TOKEN_ID(), amount: AMOUNT(), data: DATA(success: true));
  erc1155._mint_batch(to: owner, ids: TOKEN_IDS(), amounts: AMOUNTS(), data: DATA(success: true));

  erc1155
}

fn setup_dispatcher(uri: Span<felt252>) -> ERC1155ABIDispatcher {
  let mut calldata = ArrayTrait::new();

  uri.serialize(ref output: calldata);

  let mut erc1155_contract_address = utils::deploy(ERC1155::TEST_CLASS_HASH, calldata);
  ERC1155ABIDispatcher { contract_address: erc1155_contract_address }
}

fn setup_receiver() -> starknet::ContractAddress {
  utils::deploy(ERC1155Receiver::TEST_CLASS_HASH, ArrayTrait::new())
}

fn setup_account() -> starknet::ContractAddress {
  utils::deploy(Account::TEST_CLASS_HASH, ArrayTrait::new())
}

//
// Initializers
//

#[test]
#[available_gas(20000000)]
fn test_constructor() {
  let mut erc1155 = setup_dispatcher(URI());

  assert(erc1155.uri(TOKEN_ID()) == URI(), 'uri should be URI()');

  assert(erc1155.balance_of(RECIPIENT(), TOKEN_ID()) == 0.into(), 'Balance should be zero');

  assert(erc1155.supports_interface(erc1155::interface::IERC1155_ID), 'Missing interface ID');
  assert(erc1155.supports_interface(erc1155::interface::IERC1155_METADATA_ID), 'missing interface ID');
  assert(erc1155.supports_interface(erc165::IERC165_ID), 'missing interface ID');

  assert(!erc1155.supports_interface(erc165::INVALID_ID), 'invalid interface ID');
}

#[test]
#[available_gas(20000000)]
fn test_initialize() {
  let mut erc1155 = setup();

  erc1155.initializer(URI());

  assert(erc1155.uri(TOKEN_ID()) == URI(), 'uri should be URI()');

  assert(erc1155.balance_of(RECIPIENT(), TOKEN_ID()) == 0.into(), 'Balance should be zero');

  assert(erc1155.supports_interface(erc1155::interface::IERC1155_ID), 'Missing interface ID');
  assert(erc1155.supports_interface(erc1155::interface::IERC1155_METADATA_ID), 'missing interface ID');
  assert(erc1155.supports_interface(erc165::IERC165_ID), 'missing interface ID');

  assert(!erc1155.supports_interface(erc165::INVALID_ID), 'invalid interface ID');
}

//
// Balances
//

#[test]
#[available_gas(20000000)]
fn test_balance_of() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);

  assert(erc1155.balance_of(account: owner, id: TOKEN_ID()) == AMOUNT(), 'Balance should be zero');
}

#[test]
#[available_gas(20000000)]
fn test_balance_of_zero() {
  let mut erc1155 = setup();

  assert(erc1155.balance_of(account: ZERO(), id: TOKEN_ID()) == 0.into(), 'Balance should be zero');
}

#[test]
#[available_gas(20000000)]
fn test_balance_of_batch() {
  let mut erc1155 = setup();

  let mut accounts = ArrayTrait::<starknet::ContractAddress>::new();
  accounts.append(setup_receiver());
  accounts.append(setup_receiver());
  accounts.append(setup_receiver());

  let mut ids = ArrayTrait::<u256>::new();
  ids.append('id1'.into());
  ids.append('id2'.into());
  ids.append('id3'.into());

  let mut amounts = ArrayTrait::<u256>::new();
  amounts.append('amount1'.into());
  amounts.append('amount2'.into());
  amounts.append('amount3'.into());

  // Mint
  erc1155._mint(to: *accounts.at(0), id: *ids.at(0), amount: *amounts.at(0), data: DATA(success: true));
  erc1155._mint(to: *accounts.at(1), id: *ids.at(1), amount: *amounts.at(1), data: DATA(success: true));
  erc1155._mint(to: *accounts.at(2), id: *ids.at(2), amount: *amounts.at(2), data: DATA(success: true));

  assert(
    erc1155.balance_of_batch(accounts: accounts.span(), ids: ids.span()).span() == amounts.span(),
    'Balances should be amounts'
  );
}

//
// URI
//

#[test]
#[available_gas(20000000)]
fn test_set_uri() {
  let mut erc1155 = setup();

  let mut new_URI = ArrayTrait::new();
  new_URI.append('random');
  new_URI.append(0);
  new_URI.append('felt252');
  new_URI.append(0);
  new_URI.append('elements');
  new_URI.append('.');
  erc1155._set_uri(new_uri: new_URI.span());

  assert(new_URI.span() == erc1155.uri(0.into()), 'uri should be new_URI');
}

#[test]
#[available_gas(20000000)]
fn test_set_empty_uri() {
  let mut erc1155 = setup();

  let empty_uri = ArrayTrait::new().span();
  erc1155._set_uri(new_uri: empty_uri);

  assert(empty_uri == erc1155.uri(0.into()), 'uri should be empty');
}

//
// Approval
//

#[test]
#[available_gas(20000000)]
fn test_is_approved_for_all() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let operator = OPERATOR();
  let token_id = TOKEN_ID();

  assert(!erc1155.is_approved_for_all(owner, operator), 'Should not be approved');

  testing::set_caller_address(owner);
  erc1155.set_approval_for_all(operator, true);

  assert(erc1155.is_approved_for_all(owner, operator), 'Should be approved');
}

#[test]
#[available_gas(20000000)]
fn test_set_approval_for_all() {
  let mut erc1155 = setup();

  testing::set_caller_address(OWNER());
  assert(!erc1155.is_approved_for_all(OWNER(), OPERATOR()), 'Invalid default value');

  erc1155.set_approval_for_all(OPERATOR(), true);
  assert(erc1155.is_approved_for_all(OWNER(), OPERATOR()), 'Operator not approved correctly');

  erc1155.set_approval_for_all(OPERATOR(), false);
  assert(!erc1155.is_approved_for_all(OWNER(), OPERATOR()), 'Approval not revoked correctly');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: self approval', ))]
fn test_set_approval_for_all_owner_equal_operator_true() {
  let mut erc1155 = setup();

  testing::set_caller_address(OWNER());
  erc1155.set_approval_for_all(OWNER(), true);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: self approval', ))]
fn test_set_approval_for_all_owner_equal_operator_false() {
  let mut erc1155 = setup();

  testing::set_caller_address(OWNER());
  erc1155.set_approval_for_all(OWNER(), false);
}

#[test]
#[available_gas(20000000)]
fn test__set_approval_for_all() {
  let mut erc1155 = setup();

  assert(!erc1155.is_approved_for_all(OWNER(), OPERATOR()), 'Invalid default value');

  erc1155._set_approval_for_all(OWNER(), OPERATOR(), true);
  assert(erc1155.is_approved_for_all(OWNER(), OPERATOR()), 'Operator not approved correctly');

  erc1155._set_approval_for_all(OWNER(), OPERATOR(), false);
  assert(!erc1155.is_approved_for_all(OWNER(), OPERATOR()), 'Operator not approved correctly');
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: self approval', ))]
fn test__set_approval_for_all_owner_equal_operator_true() {
  let mut erc1155 = setup();

  erc1155._set_approval_for_all(OWNER(), OWNER(), true);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: self approval', ))]
fn test__set_approval_for_all_owner_equal_operator_false() {
  let mut erc1155 = setup();

  erc1155._set_approval_for_all(OWNER(), OWNER(), false);
}

//
// Safe transfer
//

#[test]
#[available_gas(20000000)]
fn test_safe_transfer_from_to_receiver() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let recipient = setup_receiver();
  let token_id = TOKEN_ID();
  let amount = AMOUNT();

  assert_state_before_transfer(ref :erc1155, :owner, :recipient, :token_id, :amount);

  testing::set_caller_address(owner);
  erc1155.safe_transfer_from(from: owner, to: recipient, id: token_id, :amount, data: DATA(success: true));

  assert_state_after_transfer(ref :erc1155, :owner, :recipient, :token_id, :amount);
}

#[test]
#[available_gas(20000000)]
fn test_multiple_safe_transfer_from_to_receiver() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let recipient = setup_receiver();
  let token_id = TOKEN_ID();
  let amount = AMOUNT();

  assert_state_before_transfer(ref :erc1155, :owner, :recipient, :token_id, :amount);

  testing::set_caller_address(owner);
  erc1155.safe_transfer_from(from: owner, to: recipient, id: token_id, amount: AMOUNT_1(), data: DATA(success: true));
  erc1155.safe_transfer_from(from: owner, to: recipient, id: token_id, amount: AMOUNT_2(), data: DATA(success: true));
  erc1155.safe_transfer_from(from: owner, to: recipient, id: token_id, amount: AMOUNT_3(), data: DATA(success: true));

  assert_state_after_transfer(ref :erc1155, :owner, :recipient, :token_id, :amount);
}

#[test]
#[available_gas(20000000)]
fn test_safe_transfer_from_to_account() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let account = setup_account();
  let token_id = TOKEN_ID();
  let amount = AMOUNT();

  assert_state_before_transfer(ref :erc1155, :owner, recipient: account, :token_id, :amount);

  testing::set_caller_address(owner);
  erc1155.safe_transfer_from(from: owner, to: account, id: token_id, :amount, data: DATA(success: true));

  assert_state_after_transfer(ref :erc1155, :owner, recipient: account, :token_id, :amount);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: safe transfer failed', ))]
fn test_safe_transfer_from_to_receiver_failure() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let recipient = setup_receiver();
  let token_id = TOKEN_ID();
  let amount = AMOUNT();

  testing::set_caller_address(owner);
  erc1155.safe_transfer_from(from: owner, to: recipient, id: token_id, :amount, data: DATA(success: false));
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', ))]
fn test_safe_transfer_from_to_non_receiver() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let recipient = utils::deploy(ERC1155NonReceiver::TEST_CLASS_HASH, ArrayTrait::new());
  let token_id = TOKEN_ID();
  let amount = AMOUNT();

  testing::set_caller_address(owner);
  erc1155.safe_transfer_from(from: owner, to: recipient, id: token_id, :amount, data: DATA(success: true));
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: transfer from 0 addr', ))]
fn test_safe_transfer_from_nonexistent() {
  let mut erc1155 = setup();

  let token_id = TOKEN_ID();
  let amount = AMOUNT();

  erc1155.safe_transfer_from(from: ZERO(), to: RECIPIENT(), id: token_id, :amount, data: DATA(success: true));
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: transfer to 0 addr', ))]
fn test_safe_transfer_from_to_zero() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);

  testing::set_caller_address(owner);
  erc1155.safe_transfer_from(from: owner, to: ZERO(), id: TOKEN_ID(), amount: AMOUNT(), data: DATA(success: true));
}

#[test]
#[available_gas(20000000)]
fn test_safe_transfer_from_to_owner() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let token_id = TOKEN_ID();
  let amount = AMOUNT();

  assert(erc1155.balance_of(account: owner, id: token_id) == amount, 'Balance of owner before');

  testing::set_caller_address(owner);
  erc1155.safe_transfer_from(from: owner, to: owner, id: token_id, :amount, data: DATA(success: true));

  assert(erc1155.balance_of(account: owner, id: token_id) == amount, 'Balance of owner after');
}

#[test]
#[available_gas(20000000)]
fn test_safe_transfer_from_approved_for_all() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let recipient = setup_receiver();
  let token_id = TOKEN_ID();
  let amount = AMOUNT();

  assert_state_before_transfer(ref :erc1155, :owner, :recipient, :token_id, :amount);

  testing::set_caller_address(owner);
  erc1155.set_approval_for_all(OPERATOR(), true);

  testing::set_caller_address(OPERATOR());
  erc1155.safe_transfer_from(from: owner, to: recipient, id: token_id, :amount, data: DATA(success: true));

  assert_state_after_transfer(ref :erc1155, :owner, :recipient, :token_id, :amount);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: caller not allowed', ))]
fn test_safe_transfer_from_unauthorized() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let token_id = TOKEN_ID();
  let amount = AMOUNT();

  testing::set_caller_address(OTHER());
  erc1155.safe_transfer_from(from: owner, to: RECIPIENT(), id: token_id, :amount, data: DATA(success: true));
}

//
// Safe batch transfer
//

#[test]
#[available_gas(20000000)]
fn test_safe_batch_transfer_from_to_receiver() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let recipient = setup_receiver();
  let token_ids = TOKEN_IDS();
  let amounts = AMOUNTS();

  assert_state_before_transfer(ref :erc1155, :owner, :recipient, token_id: TOKEN_ID_1(), amount: AMOUNT_1());
  assert_state_before_transfer(ref :erc1155, :owner, :recipient, token_id: TOKEN_ID_2(), amount: AMOUNT_2());
  assert_state_before_transfer(ref :erc1155, :owner, :recipient, token_id: TOKEN_ID_3(), amount: AMOUNT_3());

  testing::set_caller_address(owner);
  erc1155.safe_batch_transfer_from(from: owner, to: recipient, ids: token_ids, :amounts, data: DATA(success: true));

  assert_state_after_transfer(ref :erc1155, :owner, :recipient, token_id: TOKEN_ID_1(), amount: AMOUNT_1());
  assert_state_after_transfer(ref :erc1155, :owner, :recipient, token_id: TOKEN_ID_2(), amount: AMOUNT_2());
  assert_state_after_transfer(ref :erc1155, :owner, :recipient, token_id: TOKEN_ID_3(), amount: AMOUNT_3());
}

#[test]
#[available_gas(20000000)]
fn test_safe_batch_transfer_from_to_account() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let account = setup_account();
  let token_ids = TOKEN_IDS();
  let amounts = AMOUNTS();

  assert_state_before_transfer(ref :erc1155, :owner, recipient: account, token_id: TOKEN_ID_1(), amount: AMOUNT_1());
  assert_state_before_transfer(ref :erc1155, :owner, recipient: account, token_id: TOKEN_ID_2(), amount: AMOUNT_2());
  assert_state_before_transfer(ref :erc1155, :owner, recipient: account, token_id: TOKEN_ID_3(), amount: AMOUNT_3());

  testing::set_caller_address(owner);
  erc1155.safe_batch_transfer_from(from: owner, to: account, ids: token_ids, :amounts, data: DATA(success: true));

  assert_state_after_transfer(ref :erc1155, :owner, recipient: account, token_id: TOKEN_ID_1(), amount: AMOUNT_1());
  assert_state_after_transfer(ref :erc1155, :owner, recipient: account, token_id: TOKEN_ID_2(), amount: AMOUNT_2());
  assert_state_after_transfer(ref :erc1155, :owner, recipient: account, token_id: TOKEN_ID_3(), amount: AMOUNT_3());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: safe transfer failed', ))]
fn test_safe_batch_transfer_from_to_receiver_failure() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let recipient = setup_receiver();
  let token_ids = TOKEN_IDS();
  let amounts = AMOUNTS();

  testing::set_caller_address(owner);
  erc1155.safe_batch_transfer_from(from: owner, to: recipient, ids: token_ids, :amounts, data: DATA(success: false));
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', ))]
fn test_safe_batch_transfer_from_to_non_receiver() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let recipient = utils::deploy(ERC1155NonReceiver::TEST_CLASS_HASH, ArrayTrait::new());
  let token_ids = TOKEN_IDS();
  let amounts = AMOUNTS();

  testing::set_caller_address(owner);
  erc1155.safe_batch_transfer_from(from: owner, to: recipient, ids: token_ids, :amounts, data: DATA(success: true));
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: transfer from 0 addr', ))]
fn test_safe_batch_transfer_from_nonexistent() {
  let mut erc1155 = setup();

  let token_ids = TOKEN_IDS();
  let amounts = AMOUNTS();

  erc1155.safe_batch_transfer_from(from: ZERO(), to: RECIPIENT(), ids: token_ids, :amounts, data: DATA(success: true));
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: transfer to 0 addr', ))]
fn test_safe_batch_transfer_from_to_zero() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let token_ids = TOKEN_IDS();
  let amounts = AMOUNTS();

  testing::set_caller_address(owner);
  erc1155.safe_batch_transfer_from(from: owner, to: ZERO(), ids: token_ids, :amounts, data: DATA(success: true));
}

#[test]
#[available_gas(20000000)]
fn test_safe_batch_transfer_from_to_owner() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let token_ids = TOKEN_IDS();
  let amounts = AMOUNTS();

  let mut owners = ArrayTrait::<starknet::ContractAddress>::new();
  owners.append(owner);
  owners.append(owner);
  owners.append(owner);

  assert(
    erc1155.balance_of_batch(accounts: owners.span(), ids: TOKEN_IDS()).span() == amounts,
    'Balances of owner before'
  );

  testing::set_caller_address(owner);
  erc1155.safe_batch_transfer_from(from: owner, to: owner, ids: token_ids, :amounts, data: DATA(success: true));

  assert(
    erc1155.balance_of_batch(accounts: owners.span(), ids: TOKEN_IDS()).span() == amounts,
    'Balances of owner after'
  );
}

#[test]
#[available_gas(20000000)]
fn test_safe_batch_transfer_from_approved_for_all() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let recipient = setup_receiver();
  let token_ids = TOKEN_IDS();
  let amounts = AMOUNTS();

  assert_state_before_transfer(ref :erc1155, :owner, :recipient, token_id: TOKEN_ID_1(), amount: AMOUNT_1());
  assert_state_before_transfer(ref :erc1155, :owner, :recipient, token_id: TOKEN_ID_2(), amount: AMOUNT_2());
  assert_state_before_transfer(ref :erc1155, :owner, :recipient, token_id: TOKEN_ID_3(), amount: AMOUNT_3());

  testing::set_caller_address(owner);
  erc1155.set_approval_for_all(OPERATOR(), true);

  testing::set_caller_address(OPERATOR());
  erc1155.safe_batch_transfer_from(from: owner, to: recipient, ids: token_ids, :amounts, data: DATA(success: true));

  assert_state_after_transfer(ref :erc1155, :owner, :recipient, token_id: TOKEN_ID_1(), amount: AMOUNT_1());
  assert_state_after_transfer(ref :erc1155, :owner, :recipient, token_id: TOKEN_ID_2(), amount: AMOUNT_2());
  assert_state_after_transfer(ref :erc1155, :owner, :recipient, token_id: TOKEN_ID_3(), amount: AMOUNT_3());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: caller not allowed', ))]
fn test_safe_batch_transfer_from_unauthorized() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let token_ids = TOKEN_IDS();
  let amounts = AMOUNTS();

  testing::set_caller_address(OTHER());
  erc1155.safe_batch_transfer_from(from: owner, to: RECIPIENT(), ids: token_ids, :amounts, data: DATA(success: true));
}

//
// Mint
//

#[test]
#[available_gas(20000000)]
fn test__mint_to_receiver() {
  let mut erc1155 = setup();

  let recipient = setup_receiver();
  let token_id = TOKEN_ID();
  let amount = AMOUNT();

  assert_state_before_mint(ref :erc1155, :recipient, :token_id);

  erc1155._mint(to: recipient, id: token_id, :amount, data: DATA(success: true));

  assert_state_after_mint(ref :erc1155, :recipient, :token_id, :amount);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: mint to 0 addr', ))]
fn test__mint_to_zero() {
  let mut erc1155 = setup();

  erc1155._mint(to: ZERO(), id: TOKEN_ID(), amount: AMOUNT(), data: DATA(success: true));
}

#[test]
#[available_gas(20000000)]
fn test__mint_to_account() {
  let mut erc1155 = setup();

  let account = setup_account();
  let token_id = TOKEN_ID();
  let amount = AMOUNT();

  assert_state_before_mint(ref :erc1155, recipient: account, :token_id);

  erc1155._mint(to: account, id: token_id, :amount, data: DATA(success: true));

  assert_state_after_mint(ref :erc1155, recipient: account, :token_id, :amount);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', ))]
fn test__mint_to_non_receiver() {
  let mut erc1155 = setup();

  let recipient = utils::deploy(ERC1155NonReceiver::TEST_CLASS_HASH, ArrayTrait::new());
  let token_id = TOKEN_ID();
  let amount = AMOUNT();

  erc1155._mint(to: recipient, id: token_id, :amount, data: DATA(success: true));
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: safe transfer failed', ))]
fn test__mint_to_receiver_failure() {
  let mut erc1155 = setup();

  let recipient = setup_receiver();
  let token_id = TOKEN_ID();
  let amount = AMOUNT();

  erc1155._mint(to: recipient, id: token_id, :amount, data: DATA(success: false));
}

#[test]
#[available_gas(20000000)]
fn test_multiple__mint_to_receiver() {
  let mut erc1155 = setup();

  let recipient = setup_receiver();
  let token_id = TOKEN_ID();
  let amount = AMOUNT();

  assert_state_before_mint(ref :erc1155, :recipient, :token_id);

  erc1155._mint(to: recipient, id: token_id, amount: AMOUNT_1(), data: DATA(success: true));
  erc1155._mint(to: recipient, id: token_id, amount: AMOUNT_2(), data: DATA(success: true));
  erc1155._mint(to: recipient, id: token_id, amount: AMOUNT_3(), data: DATA(success: true));

  assert_state_after_mint(ref :erc1155, :recipient, :token_id, :amount);
}

// Mint batch

#[test]
#[available_gas(20000000)]
fn test__mint_batch_to_receiver() {
  let mut erc1155 = setup();

  let recipient = setup_receiver();
  let token_ids = TOKEN_IDS();
  let amounts = AMOUNTS();

  assert_state_before_mint(ref :erc1155, :recipient, token_id: TOKEN_ID_1());
  assert_state_before_mint(ref :erc1155, :recipient, token_id: TOKEN_ID_2());
  assert_state_before_mint(ref :erc1155, :recipient, token_id: TOKEN_ID_3());

  erc1155._mint_batch(to: recipient, ids: token_ids, :amounts, data: DATA(success: true));

  assert_state_after_mint(ref :erc1155, :recipient, token_id: TOKEN_ID_1(), amount: AMOUNT_1());
  assert_state_after_mint(ref :erc1155, :recipient, token_id: TOKEN_ID_2(), amount: AMOUNT_2());
  assert_state_after_mint(ref :erc1155, :recipient, token_id: TOKEN_ID_3(), amount: AMOUNT_3());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: mint to 0 addr', ))]
fn test__mint_batch_to_zero() {
  let mut erc1155 = setup();

  erc1155._mint_batch(to: ZERO(), ids: TOKEN_IDS(), amounts: AMOUNTS(), data: DATA(success: true));
}

#[test]
#[available_gas(20000000)]
fn test__mint_batch_to_account() {
  let mut erc1155 = setup();

  let account = setup_account();
  let token_ids = TOKEN_IDS();
  let amounts = AMOUNTS();

  assert_state_before_mint(ref :erc1155, recipient: account, token_id: TOKEN_ID_1());
  assert_state_before_mint(ref :erc1155, recipient: account, token_id: TOKEN_ID_2());
  assert_state_before_mint(ref :erc1155, recipient: account, token_id: TOKEN_ID_3());

  erc1155._mint_batch(to: account, ids: token_ids, :amounts, data: DATA(success: true));

  assert_state_after_mint(ref :erc1155, recipient: account, token_id: TOKEN_ID_1(), amount: AMOUNT_1());
  assert_state_after_mint(ref :erc1155, recipient: account, token_id: TOKEN_ID_2(), amount: AMOUNT_2());
  assert_state_after_mint(ref :erc1155, recipient: account, token_id: TOKEN_ID_3(), amount: AMOUNT_3());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ENTRYPOINT_NOT_FOUND', ))]
fn test__mint_batch_to_non_receiver() {
  let mut erc1155 = setup();

  let recipient = utils::deploy(ERC1155NonReceiver::TEST_CLASS_HASH, ArrayTrait::new());
  let token_ids = TOKEN_IDS();
  let amounts = AMOUNTS();

  erc1155._mint_batch(to: recipient, ids: token_ids, :amounts, data: DATA(success: true));
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: safe transfer failed', ))]
fn test__mint_batch_to_receiver_failure() {
  let mut erc1155 = setup();

  let recipient = setup_receiver();
  let token_ids = TOKEN_IDS();
  let amounts = AMOUNTS();

  erc1155._mint_batch(to: recipient, ids: token_ids, :amounts, data: DATA(success: false));
}

// Burn

#[test]
#[available_gas(20000000)]
fn test__burn_from_owner() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let token_id = TOKEN_ID();
  let amount = AMOUNT();

  assert_state_before_burn(ref :erc1155, :owner, :token_id, :amount);

  testing::set_caller_address(owner);
  erc1155._burn(from: owner, id: token_id, :amount);

  assert_state_after_burn(ref :erc1155, :owner, :token_id);
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: burn from 0 addr', ))]
fn test__burn_from_zero() {
  let mut erc1155 = setup();

  erc1155._burn(from: ZERO(), id: TOKEN_ID(), amount: AMOUNT());
}

#[test]
#[available_gas(20000000)]
#[should_panic(expected: ('ERC1155: insufficient balance', ))]
fn test__burn_nonexistant() {
  let mut erc1155 = setup();

  erc1155._burn(from: OWNER(), id: TOKEN_ID(), amount: AMOUNT());
}

// Burn batch

#[test]
#[available_gas(20000000)]
fn test__burn_batch_from_owner() {
  let owner = setup_receiver();
  let mut erc1155 = setup_with_owner(owner);
  let token_ids = TOKEN_IDS();
  let amounts = AMOUNTS();

  assert_state_before_burn(ref :erc1155, :owner, token_id: TOKEN_ID_1(), amount: AMOUNT_1());
  assert_state_before_burn(ref :erc1155, :owner, token_id: TOKEN_ID_2(), amount: AMOUNT_2());
  assert_state_before_burn(ref :erc1155, :owner, token_id: TOKEN_ID_3(), amount: AMOUNT_3());

  testing::set_caller_address(owner);
  erc1155._burn_batch(from: owner, ids: token_ids, :amounts);

  assert_state_after_burn(ref :erc1155, :owner, token_id: TOKEN_ID_1());
  assert_state_after_burn(ref :erc1155, :owner, token_id: TOKEN_ID_2());
  assert_state_after_burn(ref :erc1155, :owner, token_id: TOKEN_ID_3());
}

//
// Helpers
//

// Transfer

fn assert_state_before_transfer(
  ref erc1155: ERC1155ContractState,
  owner: starknet::ContractAddress,
  recipient: starknet::ContractAddress,
  token_id: u256,
  amount: u256
) {
  assert(erc1155.balance_of(owner, token_id) == amount, 'Balance of owner before');
  assert(erc1155.balance_of(recipient, token_id) == 0.into(), 'Balance of recipient before');
}

fn assert_state_after_transfer(
  ref erc1155: ERC1155ContractState,
  owner: starknet::ContractAddress,
  recipient: starknet::ContractAddress,
  token_id: u256,
  amount: u256
) {
  assert(erc1155.balance_of(owner, token_id) == 0.into(), 'Balance of owner after');
  assert(erc1155.balance_of(recipient, token_id) == amount, 'Balance of recipient after');
}

// Mint

fn assert_state_before_mint(ref erc1155: ERC1155ContractState, recipient: starknet::ContractAddress, token_id: u256) {
  assert(erc1155.balance_of(recipient, token_id) == 0.into(), 'Balance of recipient before');
}

fn assert_state_after_mint(
  ref erc1155: ERC1155ContractState,
  recipient: starknet::ContractAddress,
  token_id: u256,
  amount: u256
) {
  assert(erc1155.balance_of(recipient, token_id) == amount, 'Balance of recipient after');
}

// Burn

fn assert_state_before_burn(
  ref erc1155: ERC1155ContractState,
  owner: starknet::ContractAddress,
  token_id: u256,
  amount: u256
) {
  assert_state_after_mint(ref :erc1155, recipient: owner, :token_id, :amount);
}

fn assert_state_after_burn(ref erc1155: ERC1155ContractState, owner: starknet::ContractAddress, token_id: u256) {
  assert_state_before_mint(ref :erc1155, recipient: owner, :token_id);
}
