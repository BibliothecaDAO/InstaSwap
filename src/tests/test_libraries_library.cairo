use core::array::ArrayTrait;
use starknet::contract_address_const;
use starknet::ContractAddress;
use starknet::testing::set_caller_address;
use starknet::testing::set_block_timestamp;
use integer::u256;
use integer::u256_from_felt252;
use integer::BoundedInt;
use traits::Into;
use traits::TryInto;
use option::OptionTrait;
use debug::PrintTrait;

//
// Tests
//

#[test]
#[available_gas(2000000)]
fn test_get_currency_amount_when_buy() {
    
}