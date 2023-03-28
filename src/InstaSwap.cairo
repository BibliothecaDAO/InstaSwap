#[contract]
mod Traits {
    use starknet::get_caller_address;

    struct Storage {
        currency_address: ContractAddress,
        token_address: ContractAddress,
        currency_reserves: LegacyMap::<ContractAddress, felt>,
        lp_reserves: LegacyMap::<ContractAddress, felt>,
        lp_fee_thousands: LegacyMap::<ContractAddress, felt>,
        royalty_fee_thousands: LegacyMap::<ContractAddress, felt>,
        royalty_fee_address: LegacyMap::<ContractAddress, felt>,
    }

    #[constructor]
    fn constructor(
        uri: felt252,
        currency_address: felt252,
        token_address: felt252,
        lp_fee_thousands: felt252,
        royalty_fee_thousands: felt252,
        royalty_fee_address: felt252
    ) {
        // setup
    }

    trait InstaSwap {
        // set initial liquidity
        fn initial_liquidity(
            currency_amounts: Array<felt252>,
            token_ids: Array<felt252>,
            token_amounts: Array<felt252>
        );
        // add liquidity
        fn add_liquidity(
            currency_amounts: Array<felt252>,
            token_ids: Array<felt252>,
            token_amounts: Array<felt252>
        );
    }

    impl Trait of InstaSwap {
        fn initial_liquidity(
            currency_amounts: Array<felt252>,
            token_ids: Array<felt252>,
            token_amounts: Array<felt252>
        ) {
            let caller = get_caller_address();
            names::write(caller, _name);
        }

        fn add_liquidity(
            currency_amounts: Array<felt252>,
            token_ids: Array<felt252>,
            token_amounts: Array<felt252>
        ) -> felt {
            names::read(address)
        }
    }

    #[external]
    fn initial_liquidity(
        currency_amounts: Array<felt252>, token_ids: Array<felt252>, token_amounts: Array<felt252>
    ) {
        InstaSwap::initial_liquidity(currency_amounts, token_ids, token_amounts);
    }
}
