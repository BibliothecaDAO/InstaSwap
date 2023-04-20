use array::ArrayTrait;
use option::OptionTrait;
use traits::TryInto;
use traits::Into;
use gas::get_builtin_costs;

//TODO: Remove when u256 literals are supported.
fn as_u256(high: u128, low: u128) -> u256 {
    u256 { low, high }
}
