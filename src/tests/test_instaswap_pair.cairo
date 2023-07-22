use core::serde::Serde;
use clone::Clone;
use starknet::testing;
use array::{ArrayTrait, SpanTrait, SpanCopy, SpanSerde};
use traits::Into;
use zeroable::Zeroable;
use integer::u256_from_felt252;

// locals
use rules_erc1155::erc1155;
use rules_erc1155::erc1155::{ERC1155, ERC1155ABIDispatcher, ERC1155ABIDispatcherTrait};
use rules_erc1155::erc1155::interface::IERC1155;
use rules_erc1155::erc1155::interface;

use super::utils;
use rules_utils::utils::partial_eq::SpanPartialEq;
use super::mocks::account::Account;
use starknet::ContractAddress;
use jedinft::access::ownable::{IOwnable, IOwnableDispatcher, IOwnableDispatcherTrait};
use super::mocks::erc1155_receiver::{ERC1155Receiver, ERC1155NonReceiver, SUCCESS, FAILURE};
use rules_erc1155::erc1155::erc1155::ERC1155::{
    ContractState as ERC1155ContractState, InternalTrait
};
use instaswap::instaswap_pair::{
    InstaSwapPair, IInstaSwapPairDispatcher, IInstaSwapPairDispatcherTrait
};
use debug::PrintTrait;
use instaswap::libraries::erc20::{ERC20, IERC20Dispatcher, IERC20DispatcherTrait};

use rules_utils::introspection::src5::SRC5;
use rules_utils::introspection::interface::{ ISRC5, ISRC5_ID };

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

fn CURRENCY_ADDRESS() -> starknet::ContractAddress {
    starknet::contract_address_const::<1132>()
}

fn TOKEN_ADDRESS() -> starknet::ContractAddress {
    starknet::contract_address_const::<4343>()
}

fn LP_FEE_THOUSAND() -> u256 {
    3.into()
}

fn ROYALTY_FEE_THOUSAND() -> u256 {
    3.into()
}

fn ROYALTY_FEE_ADDRESS() -> starknet::ContractAddress {
    starknet::contract_address_const::<4344>()
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

fn setup_dispatcher(uri: Span<felt252>) -> ContractAddress {
    let mut calldata = ArrayTrait::new();

    uri.serialize(ref output: calldata);
    CURRENCY_ADDRESS().serialize(ref output: calldata);
    TOKEN_ADDRESS().serialize(ref output: calldata);
    LP_FEE_THOUSAND().serialize(ref output: calldata);
    ROYALTY_FEE_THOUSAND().serialize(ref output: calldata);
    ROYALTY_FEE_ADDRESS().serialize(ref output: calldata);
    OWNER().serialize(ref output: calldata);

    let mut instaswap_pair_contract_address = utils::deploy(
        InstaSwapPair::TEST_CLASS_HASH, calldata
    );
    instaswap_pair_contract_address
}

fn setup_receiver() -> starknet::ContractAddress {
    utils::deploy(ERC1155Receiver::TEST_CLASS_HASH, ArrayTrait::new())
}

fn setup_account() -> starknet::ContractAddress {
    utils::deploy(Account::TEST_CLASS_HASH, ArrayTrait::new())
}

fn setup_erc20() -> ContractAddress {
    let mut calldata = ArrayTrait::new();

    OWNER().serialize(ref output: calldata);
    TOKEN_ADDRESS().serialize(ref output: calldata);

    let mut erc20_contract_address = utils::deploy(ERC20::TEST_CLASS_HASH, calldata);
    erc20_contract_address
}

//
// Initializers
//

#[test]
#[available_gas(20000000)]
fn test_constructor() {
    starknet::testing::set_caller_address(starknet::contract_address_const::<1>());
    let mut instaswap_pair_address = setup_dispatcher(URI());

    // test instaswap_pair functions
    let mut instaswap_pair = IInstaSwapPairDispatcher { contract_address: instaswap_pair_address };
    assert(instaswap_pair.get_currency_address() == CURRENCY_ADDRESS(), 'currency address failed');
    assert(instaswap_pair.get_token_address() == TOKEN_ADDRESS(), 'token address failed');
    assert(instaswap_pair.get_lp_fee_thousand() == LP_FEE_THOUSAND(), 'lp fee thousand failed');
    assert(
        instaswap_pair.get_royalty_fee_thousand() == ROYALTY_FEE_THOUSAND(),
        'royalty fee thousand failed'
    );
    assert(
        instaswap_pair.get_royalty_fee_address() == ROYALTY_FEE_ADDRESS(),
        'royalty fee address failed'
    );

    // test erc1155 functions
    let mut erc1155 = ERC1155ABIDispatcher { contract_address: instaswap_pair_address };

    assert(erc1155.uri(TOKEN_ID()) == URI(), 'uri should be URI()');

    assert(erc1155.balance_of(RECIPIENT(), TOKEN_ID()) == 0.into(), 'Balance should be zero');

    assert(erc1155.balance_of(RECIPIENT(), TOKEN_ID()) == 0.into(), 'Balance should be zero');

    assert(erc1155.supports_interface(interface::IERC1155_ID), 'Missing interface ID');
    assert(erc1155.supports_interface(interface::IERC1155_METADATA_ID), 'missing interface ID');
    assert(erc1155.supports_interface(ISRC5_ID), 'missing interface ID');
    let mut ownable = IOwnableDispatcher { contract_address: instaswap_pair_address };
    ownable.owner().print();
    assert(ownable.owner() == OWNER(), 'owner should be OWNER()');
}