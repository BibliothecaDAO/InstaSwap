use core::serde::Serde;
use clone::Clone;
use starknet::testing;
use array::{ArrayTrait, SpanTrait, SpanCopy, SpanSerde};
use traits::Into;
use zeroable::Zeroable;
use integer::u256_from_felt252;

use core::result::ResultTrait;
use option::OptionTrait;
use starknet::class_hash::Felt252TryIntoClassHash;
use traits::TryInto;
use starknet::SyscallResultTrait;

// locals
use rules_erc1155::erc1155;
use instaswap::erc1155::erc1155::{ERC1155, ERC1155ABIDispatcher, ERC1155ABIDispatcherTrait};
use rules_erc1155::erc1155::interface::IERC1155;
use rules_erc1155::erc1155::interface;

use super::utils;
use rules_utils::utils::partial_eq::SpanPartialEq;
use super::mocks::account::Account;
use starknet::ContractAddress;
use instaswap::access::ownable::{IOwnable, IOwnableDispatcher, IOwnableDispatcherTrait};
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
use rules_utils::introspection::interface::{ISRC5, ISRC5_ID};

fn URI() -> Span<felt252> {
    let mut uri = ArrayTrait::new();

    uri.append(111);
    uri.append(222);
    uri.append(333);

    uri.span()
}
// TOKEN ID

fn TOKEN_ID_1() -> u256 {
    '1'.into()
}

fn TOKEN_ID_2() -> u256 {
    '2'.into()
}

fn TOKEN_ID_3() -> u256 {
    '3'.into()
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
    100000.into()
}

fn AMOUNT_2() -> u256 {
    100000.into()
}

fn AMOUNT_3() -> u256 {
    100000.into()
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

// fn setup() -> ERC1155ContractState {
//     let owner = setup_receiver();
//     setup_with_owner(owner)
// }

// fn setup_with_owner(owner: starknet::ContractAddress) -> ERC1155ContractState {
//     let mut erc1155 = ERC1155::contract_state_for_testing();

//     erc1155.initializer(URI());
//     erc1155._mint(to: owner, id: TOKEN_ID(), amount: AMOUNT(), data: DATA(success: true));
//     erc1155._mint_batch(to: owner, ids: TOKEN_IDS(), amounts: AMOUNTS(), data: DATA(success: true));

//     erc1155
// }

fn setup_instaswap(
    currency_address: ContractAddress, token_address: ContractAddress, uri: Span<felt252>
) -> ContractAddress {
    let mut calldata = ArrayTrait::new();

    uri.serialize(ref output: calldata);
    currency_address.serialize(ref output: calldata);
    token_address.serialize(ref output: calldata);
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

    'erc20_token'.serialize(ref output: calldata);
    'T20'.serialize(ref output: calldata);
    10000000000000_u256.serialize(ref output: calldata);
    OWNER().serialize(ref output: calldata);

    let mut erc20_contract_address = utils::deploy(ERC20::TEST_CLASS_HASH, calldata);
    erc20_contract_address
}

fn setup_erc1155() -> ContractAddress {
    let mut calldata = ArrayTrait::new();

    let mut uri = ArrayTrait::new();
    uri.append(111);
    uri.append(222);
    uri.serialize(ref output: calldata);
    let mut contract_address = utils::deploy(ERC1155::TEST_CLASS_HASH, calldata);
    contract_address
}

//
// Initializers
//

#[test]
#[available_gas(20000000)]
fn test_constructor() {
    starknet::testing::set_contract_address(OWNER());
    let mut instaswap_pair_address = setup_instaswap(CURRENCY_ADDRESS(), TOKEN_ADDRESS(), URI());

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
    assert(ownable.owner() == OWNER(), 'owner should be OWNER()');
}


#[test]
#[available_gas(20000000)]
fn test_add_liquidity() {
    let owner = setup_receiver();
    starknet::testing::set_contract_address(owner);
    let mut block_timestamp: felt252 = 1690163135;
    starknet::testing::set_block_timestamp(block_timestamp.try_into().unwrap());

    let erc20_contract_address = setup_erc20();
    let mut erc20 = IERC20Dispatcher { contract_address: erc20_contract_address };
    // mint token to owner
    erc20.mint(owner, 100000);

    let erc1155_contract_address = setup_erc1155();
    let mut erc1155 = ERC1155ABIDispatcher { contract_address: erc1155_contract_address };
    // mint token to owner
    erc1155.mint(owner, 1, 100000);

    // assert balance
    assert(erc1155.balance_of(owner, 1) == 100000, 'Balance should be 100000');
    let instaswap_pair_address = setup_instaswap(
        erc20_contract_address, erc1155_contract_address, URI()
    );
    let mut instaswap_pair = IInstaSwapPairDispatcher { contract_address: instaswap_pair_address };
    let mut instaswap_erc1155 = ERC1155ABIDispatcher { contract_address: instaswap_pair_address };
    // approve erc20 to instaswap_pair
    erc20.approve(instaswap_pair_address, 100000);
    // approve erc1155 to instaswap_pair
    erc1155.set_approval_for_all(instaswap_pair_address, true);

    let mut max_currency_amounts = ArrayTrait::new();
    max_currency_amounts.append(100000);
    let mut token_ids = ArrayTrait::new();
    token_ids.append(1);
    let mut token_amounts = ArrayTrait::new();
    token_amounts.append(100000);


    // add liquidity
    instaswap_pair
        .add_liquidity(max_currency_amounts, token_ids, token_amounts, block_timestamp + 100);
    // assert balance
    assert(erc1155.balance_of(owner, 1) == 0.into(), 'Balance should be zero');
    assert(erc20.balance_of(owner) == 0.into(), 'Balance should be zero');
    assert(
        erc1155.balance_of(instaswap_pair_address, 1) == 100000,
        'Balance should be 100000'
    );
    assert(
        erc20.balance_of(instaswap_pair_address) == 100000,
        'Balance should be 100000'
    );
    assert(instaswap_erc1155.balance_of(owner, 1) == 100000 - 1000, 'Balance should be 100000');
    assert(instaswap_pair.get_lp_supply(1_u256) == 100000, 'Balance should be 1000');
    // second add liquidity
    erc20.mint(owner, 300000);
    erc1155.mint(owner, 1, 200000);
    erc20.approve(instaswap_pair_address, 300000);
    erc1155.set_approval_for_all(instaswap_pair_address, true);
    max_currency_amounts = ArrayTrait::new();
    max_currency_amounts.append(300000);
    token_ids = ArrayTrait::new();
    token_ids.append(1);
    token_amounts = ArrayTrait::new();
    token_amounts.append(200000);
    instaswap_pair
        .add_liquidity(max_currency_amounts, token_ids, token_amounts, block_timestamp + 100);
    assert(erc1155.balance_of(owner, 1) == 0.into(), 'Balance not correct');
    assert(erc20.balance_of(owner) == 300000 - 200000, 'Balance should be zero');
    assert(
        erc1155.balance_of(instaswap_pair_address, 1) == 100000 + 200000, 'Balance should be 200000'
    );
    assert(
        erc20.balance_of(instaswap_pair_address) == 100000 + 200000,
        'Balance not correct 1.1'
    );
    assert(instaswap_erc1155.balance_of(owner, 1) == 100000 - 1000 + 200000, 'Balance not correct 2');


}

#[test]
#[available_gas(40000000)]
fn test_remove_liquidity() {
    let owner = setup_receiver();
    starknet::testing::set_contract_address(owner);
    let mut block_timestamp: felt252 = 1690163135;
    starknet::testing::set_block_timestamp(block_timestamp.try_into().unwrap());

    let erc20_contract_address = setup_erc20();
    let mut erc20 = IERC20Dispatcher { contract_address: erc20_contract_address };
    // mint token to owner
    erc20.mint(owner, 100000);

    let erc1155_contract_address = setup_erc1155();
    let mut erc1155 = ERC1155ABIDispatcher { contract_address: erc1155_contract_address };
    // mint token to owner
    erc1155.mint(owner, 1, 100000);

    // assert balance
    assert(erc1155.balance_of(owner, 1) == 100000, 'Balance should be 100000');
    let instaswap_pair_address = setup_instaswap(
        erc20_contract_address, erc1155_contract_address, URI()
    );
    let mut instaswap_pair = IInstaSwapPairDispatcher { contract_address: instaswap_pair_address };
    let mut instaswap_erc1155 = ERC1155ABIDispatcher { contract_address: instaswap_pair_address };
    // approve erc20 to instaswap_pair
    erc20.approve(instaswap_pair_address, 100000);
    // approve erc1155 to instaswap_pair
    erc1155.set_approval_for_all(instaswap_pair_address, true);

    let mut max_currency_amounts = ArrayTrait::new();
    max_currency_amounts.append(100000);
    let mut token_ids = ArrayTrait::new();
    token_ids.append(1);
    let mut token_amounts = ArrayTrait::new();
    token_amounts.append(100000);


    // add liquidity
    instaswap_pair
        .add_liquidity(max_currency_amounts, token_ids, token_amounts, block_timestamp + 100);
    // assert balance
    assert(erc1155.balance_of(owner, 1) == 0.into(), 'Balance should be zero');
    assert(erc20.balance_of(owner) == 0.into(), 'Balance should be zero');
    assert(
        erc1155.balance_of(instaswap_pair_address, 1) == 100000,
        'Balance should be 100000'
    );
    assert(
        erc20.balance_of(instaswap_pair_address) == 100000,
        'Balance should be 100000'
    );
    assert(instaswap_erc1155.balance_of(owner, 1) == 100000 - 1000, 'Balance should be 100000');
    assert(instaswap_pair.get_lp_supply(1_u256) == 100000, 'Balance should be 1000');
    // second add liquidity
    erc20.mint(owner, 300000);
    erc1155.mint(owner, 1, 200000);
    erc20.approve(instaswap_pair_address, 300000);
    erc1155.set_approval_for_all(instaswap_pair_address, true);
    max_currency_amounts = ArrayTrait::new();
    max_currency_amounts.append(300000);
    token_ids = ArrayTrait::new();
    token_ids.append(1);
    token_amounts = ArrayTrait::new();
    token_amounts.append(200000);
    instaswap_pair
        .add_liquidity(max_currency_amounts, token_ids, token_amounts, block_timestamp + 100);
    assert(erc1155.balance_of(owner, 1) == 0.into(), 'Balance not correct');
    assert(erc20.balance_of(owner) == 300000 - 200000, 'Balance should be zero');
    assert(
        erc1155.balance_of(instaswap_pair_address, 1) == 100000 + 200000, 'Balance should be 200000'
    );
    assert(
        erc20.balance_of(instaswap_pair_address) == 100000 + 200000,
        'Balance not correct 1.1'
    );
    assert(instaswap_erc1155.balance_of(owner, 1) == 100000 - 1000 + 200000, 'Balance not correct 2');

    // remove liquidity
    let mut min_currency_amounts = ArrayTrait::new();
    min_currency_amounts.append(100000);
    token_ids = ArrayTrait::new();
    token_ids.append(1);
    let mut min_token_amounts = ArrayTrait::new();
    min_token_amounts.append(100000);
    let mut lp_amounts = ArrayTrait::new();
    lp_amounts.append(100000);
    instaswap_pair.remove_liquidity(
        min_currency_amounts,
        token_ids,
        min_token_amounts,
        lp_amounts,
        block_timestamp + 100
    );
    assert(erc1155.balance_of(owner, 1) == 100000, 'Balance1 should be 100000');
    assert(erc20.balance_of(owner) == 200000, 'Balance2 should be 200000');
    assert(
        erc1155.balance_of(instaswap_pair_address, 1) == 200000,
        'Balance3 should be 200000'
    );
    assert(
        erc20.balance_of(instaswap_pair_address) == 200000,
        'Balance4 should be 200000'
    );
    assert(instaswap_erc1155.balance_of(owner, 1) == 200000 - 1000, 'Balance5 should be 199000');
    assert(instaswap_pair.get_lp_supply(1_u256) == 200000, 'Balance6 should be 200000');


}


#[test]
#[available_gas(40000000)]
fn test_remove_liquidity_with_to_rounded_liquidity() {
    let owner = setup_receiver();
    starknet::testing::set_contract_address(owner);
    let mut block_timestamp: felt252 = 1690163135;
    starknet::testing::set_block_timestamp(block_timestamp.try_into().unwrap());

    let erc20_contract_address = setup_erc20();
    let mut erc20 = IERC20Dispatcher { contract_address: erc20_contract_address };
    // mint token to owner
    erc20.mint(owner, 131452423241);

    let erc1155_contract_address = setup_erc1155();
    let mut erc1155 = ERC1155ABIDispatcher { contract_address: erc1155_contract_address };
    // mint token to owner
    erc1155.mint(owner, 1, 619);

    let instaswap_pair_address = setup_instaswap(
        erc20_contract_address, erc1155_contract_address, URI()
    );
    let mut instaswap_pair = IInstaSwapPairDispatcher { contract_address: instaswap_pair_address };
    let mut instaswap_erc1155 = ERC1155ABIDispatcher { contract_address: instaswap_pair_address };
    // approve erc20 to instaswap_pair
    erc20.approve(instaswap_pair_address, 131452423241);
    // approve erc1155 to instaswap_pair
    erc1155.set_approval_for_all(instaswap_pair_address, true);

    let mut max_currency_amounts = ArrayTrait::new();
    max_currency_amounts.append(131452423241);
    let mut token_ids = ArrayTrait::new();
    token_ids.append(1);
    let mut token_amounts = ArrayTrait::new();
    token_amounts.append(619);

    // add liquidity
    instaswap_pair
        .add_liquidity(max_currency_amounts, token_ids, token_amounts, block_timestamp + 100);
    
    assert(instaswap_erc1155.balance_of(owner, 1) == 9019479, 'Balance not correct 1');

    // remove liquidity
    let mut min_currency_amounts = ArrayTrait::new();
    min_currency_amounts.append(100);
    token_ids = ArrayTrait::new();
    token_ids.append(1);
    let mut min_token_amounts = ArrayTrait::new();
    min_token_amounts.append(1);
    let mut lp_amounts = ArrayTrait::new();
    lp_amounts.append(131473);
    instaswap_pair.remove_liquidity(
        min_currency_amounts,
        token_ids,
        min_token_amounts,
        lp_amounts,
        block_timestamp + 100
    );
    assert(erc1155.balance_of(owner, 1) == 9, 'Balance1 wrong');
    assert(erc20.balance_of(owner) == 1920532902, 'Balance2 wrong');
    assert(
        erc1155.balance_of(instaswap_pair_address, 1) == 610,
        'Balance3 wrong'
    );
    assert(
        erc20.balance_of(instaswap_pair_address) == 129531876435,
        'Balance4 wrong'
    );
    assert(instaswap_erc1155.balance_of(owner, 1) == 8888006, 'Balance5 wrong');
    assert(instaswap_pair.get_lp_supply(1_u256) == 8889006, 'Balance6 wrong');

    // remove all liquidity
    min_currency_amounts = ArrayTrait::new();
    min_currency_amounts.append(100);
    token_ids = ArrayTrait::new();
    token_ids.append(1);
    min_token_amounts = ArrayTrait::new();
    min_token_amounts.append(1);
    lp_amounts = ArrayTrait::new();
    lp_amounts.append(8888006);
    instaswap_pair.remove_liquidity(
        min_currency_amounts,
        token_ids,
        min_token_amounts,
        lp_amounts,
        block_timestamp + 100
    );

    assert(erc1155.balance_of(owner, 1) == 618, 'Balance6 wrong');
    assert(erc20.balance_of(owner) == 131444846305, 'Balance7 wrong');
    assert(
        erc1155.balance_of(instaswap_pair_address, 1) == 1,
        'Balance8 wrong'
    );
    assert(
        erc20.balance_of(instaswap_pair_address) == 7541984,
        'Balance9 wrong'
    );
    assert(instaswap_erc1155.balance_of(owner, 1) == 0, 'Balance10 wrong');
    assert(instaswap_pair.get_lp_supply(1_u256) == 1000, 'Balance11 wrong');

}

#[test]
#[available_gas(40000000)]
fn test_buy_tokens() {
    let owner = setup_receiver();
    starknet::testing::set_contract_address(owner);
    let mut block_timestamp: felt252 = 1690163135;
    starknet::testing::set_block_timestamp(block_timestamp.try_into().unwrap());

    let erc20_contract_address = setup_erc20();
    let mut erc20 = IERC20Dispatcher { contract_address: erc20_contract_address };
    // mint token to owner
    erc20.mint(owner, 131452423241);

    let erc1155_contract_address = setup_erc1155();
    let mut erc1155 = ERC1155ABIDispatcher { contract_address: erc1155_contract_address };
    // mint token to owner
    erc1155.mint(owner, 1, 619);

    let instaswap_pair_address = setup_instaswap(
        erc20_contract_address, erc1155_contract_address, URI()
    );
    let mut instaswap_pair = IInstaSwapPairDispatcher { contract_address: instaswap_pair_address };
    let mut instaswap_erc1155 = ERC1155ABIDispatcher { contract_address: instaswap_pair_address };
    // approve erc20 to instaswap_pair
    erc20.approve(instaswap_pair_address, 131452423241);
    // approve erc1155 to instaswap_pair
    erc1155.set_approval_for_all(instaswap_pair_address, true);

    let mut max_currency_amounts = ArrayTrait::new();
    max_currency_amounts.append(101452423241);
    let mut token_ids = ArrayTrait::new();
    token_ids.append(1);
    let mut token_amounts = ArrayTrait::new();
    token_amounts.append(619);

    // add liquidity
    instaswap_pair
        .add_liquidity(max_currency_amounts, token_ids, token_amounts, block_timestamp + 100);
    
    let owner = setup_receiver();
    starknet::testing::set_contract_address(owner);
    erc20.mint(owner, 10000000000);
    erc20.approve(instaswap_pair_address, 10000000000);
    // buy tokens
    let mut max_currency_amounts = ArrayTrait::new();
    max_currency_amounts.append(10000000000);
    let mut token_ids = ArrayTrait::new();
    token_ids.append(1);
    let mut token_amounts = ArrayTrait::new();
    token_amounts.append(1);
    instaswap_pair.buy_tokens(
        max_currency_amounts,
        token_ids,
        token_amounts,
        block_timestamp + 100
    );
    assert(erc1155.balance_of(owner, 1) == 1, 'Balance1 wrong');
    assert(erc20.balance_of(owner) == 9834849564, 'Balance2 wrong');
    assert(
        erc1155.balance_of(instaswap_pair_address, 618) == 0,
        'Balance3 wrong'
    );
}

#[test]
#[available_gas(40000000)]
fn test_sell_tokens() {
    let owner = setup_receiver();
    starknet::testing::set_contract_address(owner);
    let mut block_timestamp: felt252 = 1690163135;
    starknet::testing::set_block_timestamp(block_timestamp.try_into().unwrap());

    let erc20_contract_address = setup_erc20();
    let mut erc20 = IERC20Dispatcher { contract_address: erc20_contract_address };
    // mint token to owner
    erc20.mint(owner, 131452423241);

    let erc1155_contract_address = setup_erc1155();
    let mut erc1155 = ERC1155ABIDispatcher { contract_address: erc1155_contract_address };
    // mint token to owner
    erc1155.mint(owner, 1, 619);

    let instaswap_pair_address = setup_instaswap(
        erc20_contract_address, erc1155_contract_address, URI()
    );
    let mut instaswap_pair = IInstaSwapPairDispatcher { contract_address: instaswap_pair_address };
    let mut instaswap_erc1155 = ERC1155ABIDispatcher { contract_address: instaswap_pair_address };
    // approve erc20 to instaswap_pair
    erc20.approve(instaswap_pair_address, 131452423241);
    // approve erc1155 to instaswap_pair
    erc1155.set_approval_for_all(instaswap_pair_address, true);

    let mut max_currency_amounts = ArrayTrait::new();
    max_currency_amounts.append(101452423241);
    let mut token_ids = ArrayTrait::new();
    token_ids.append(1);
    let mut token_amounts = ArrayTrait::new();
    token_amounts.append(619);

    // add liquidity
    instaswap_pair
        .add_liquidity(max_currency_amounts, token_ids, token_amounts, block_timestamp + 100);
    
    let owner = setup_receiver();
    starknet::testing::set_contract_address(owner);
    erc1155.mint(owner, 1, 1);
    erc1155.set_approval_for_all(instaswap_pair_address, true);
    // sell tokens
    let mut min_currency_amounts = ArrayTrait::new();
    min_currency_amounts.append(165150436);
    let mut token_ids = ArrayTrait::new();
    token_ids.append(1);
    let mut token_amounts = ArrayTrait::new();
    token_amounts.append(1);
    instaswap_pair.sell_tokens(
        min_currency_amounts,
        token_ids,
        token_amounts,
        block_timestamp + 100
    );

    assert(erc1155.balance_of(owner, 1) == 0, 'Balance1 wrong');
    assert(erc20.balance_of(owner) == 162653403, 'Balance2 wrong');
    assert(
        erc1155.balance_of(instaswap_pair_address, 620) == 0,
        'Balance3 wrong'
    );
}
