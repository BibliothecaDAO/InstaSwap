use array::ArrayTrait;
use option::OptionTrait;
use traits::TryInto;
use traits::Into;
use gas::get_builtin_costs;

//TODO: Remove when u256 literals are supported.
fn as_u256(high: u128, low: u128) -> u256 {
    u256 { low, high }
}

fn u256_sqrt(mut y: u256, ) -> u256 {
    //TODO need implementation
    return as_u256(100_u128, 0_u128);
}
