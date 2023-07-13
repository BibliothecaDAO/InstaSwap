use core::traits::Into;

trait AMM {
    fn get_currency_amount_when_buy(
        token_amount: u256, currency_reserve: u256, token_reserve: u256, lp_fee_thousand: u256, 
    ) -> u256;
    fn get_currency_amount_when_sell(
        token_amount: u256, currency_reserve: u256, token_reserve: u256, lp_fee_thousand: u256, 
    ) -> u256;
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
        let result = numerator / intermediate + 1.into();
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
        let denominator = token_reserve + token_amount * fee_multiplier_;
        let result = numerator / denominator;

        return result;
    }
}
