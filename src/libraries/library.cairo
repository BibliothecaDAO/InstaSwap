use core::traits::Into;
    use core::traits::TryInto;
        use option::OptionTrait;
    use option::OptionTraitImpl;

trait AMM {
    fn get_currency_amount_when_buy(
        token_amount: u256, currency_reserve: u256, token_reserve: u256, lp_fee_thousand: u256, 
    ) -> u256;
    fn get_currency_amount_when_sell(
        token_amount: u256, currency_reserve: u256, token_reserve: u256, lp_fee_thousand: u256, 
    ) -> u256;
}
trait TmpU256Div {
    fn div(lhs: u256, rhs: u256) -> u256;
}

impl U256Div of TmpU256Div {
    fn div(lhs: u256, rhs: u256) -> u256 {
        let mut lhs: u128 = lhs.try_into().unwrap();
        let mut rhs: u128 = rhs.try_into().unwrap();
        return (lhs / rhs).into();
    }
}

    impl U256Div2 of Div<u256> {
        fn div(lhs: u256, rhs: u256) -> u256 {
            let mut lhs: u128 = lhs.try_into().unwrap();
            let mut rhs: u128 = rhs.try_into().unwrap();
            return (lhs / rhs).into();
        }
    }

impl AMMImpl of AMM {

    // @dev it's almost same as swap currency for exact tokens. The currency represents ERC20, and token represents ERC1155 tokens. currency as input, token as output.
    // formula: (x - (1 + r)delta_x) * (y + delta_y) = k
    // compute: delta_x = x * delta_y / (y - delta_y) / (1 - r)
    fn get_currency_amount_when_buy(
        token_amount: u256, currency_reserve: u256, token_reserve: u256, lp_fee_thousand: u256, 
    ) -> u256 {
        let fee_multiplier_ = 1000.into() - lp_fee_thousand;
        let numerator = currency_reserve * token_amount * 1000.into();
        let denominator1 = token_reserve - token_amount;
        let intermediate = denominator1 * fee_multiplier_;
        let mut result = TmpU256Div::div(numerator , intermediate);
        let mut remain = numerator - result * intermediate;
        if remain != 0.into() {
            result += 1.into();
        }
        return result;
    }

    // @dev it's almost same as swap exact tokens for currency. token as input, currency as output.
    // r means the fee rate, not in thousand and below method is the same. When actually computing, we need to take that into account: r * 1000 = lp_fee_thousand 
    // formula: ( x - delta_x) * (y + (1 - r) * delta_y) = k
    // compute: delta_x = (1 - r) * delta_y * x / (y + (1 - r) * delta_y)
    // Why is it different from buying? Because we need to charge a fee on the source token that the user provides. When buying, the source token is the currency, while when selling, the source token is the token.
    fn get_currency_amount_when_sell(
        token_amount: u256, currency_reserve: u256, token_reserve: u256, lp_fee_thousand: u256, 
    ) -> u256 {
        let fee_multiplier_ = 1000.into() - lp_fee_thousand;
        let numerator = token_amount * currency_reserve * fee_multiplier_;
        let denominator = token_reserve * 1000 + token_amount * fee_multiplier_;
        let result = TmpU256Div::div(numerator , denominator);

        return result;
    }
}
