use starknet::ContractAddress;
use array::ArrayTrait;

#[starknet::interface]
trait IERC20<TContractState> {
    // view functions
    fn name(self: @TContractState) -> felt252;
    fn symbol(self: @TContractState) -> felt252;
    fn decimals(self: @TContractState) -> u8;
    fn total_supply(self: @TContractState) -> u256;
    fn balance_of(self: @TContractState, account: ContractAddress) -> u256;
    fn allowance(self: @TContractState, owner: ContractAddress, spender: ContractAddress) -> u256;
    // external functions
    fn transfer(ref self: TContractState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
    fn increase_allowance(ref self: TContractState, spender: ContractAddress, added_value: u256) -> bool;
    fn decrease_allowance(ref self: TContractState, spender: ContractAddress, subtracted_value: u256) -> bool;
}

#[starknet::interface]
trait IERC1155<TContractState> {
    // IERC1155
    fn balance_of(self: @TContractState, account: ContractAddress, id: u256) -> u256;
    fn balance_of_batch(self: @TContractState, accounts: Array<ContractAddress>, ids: Array<u256>) -> Array<u256>;
    fn is_approved_for_all(self: @TContractState, account: ContractAddress, operator: ContractAddress) -> bool;
    fn set_approval_for_all(ref self: TContractState, operator: ContractAddress, approved: bool);
    fn safe_transfer_from(ref self: TContractState, 
        from: ContractAddress, to: ContractAddress, id: u256, amount: u256, data: Array<felt252>
    );
    fn safe_batch_transfer_from(ref self: TContractState, 
        from: ContractAddress,
        to: ContractAddress,
        ids: Array<u256>,
        amounts: Array<u256>,
        data: Array<felt252>
    );
    // IERC1155MetadataURI
    fn uri(self: @TContractState, id: u256) -> felt252;
}

#[starknet::contract]
mod InstaSwapPair {
    use zeroable::Zeroable;
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::ContractAddress;
    use starknet::ContractAddressIntoFelt252;
    use array::ArrayTrait;
    use array::SpanTrait;
    use dict::Felt252DictTrait;
    use option::OptionTrait;
    use option::OptionTraitImpl;
    use core::ec;
    use core::traits::TryInto;
    use core::traits::Into;
    use box::BoxTrait;
    use clone::Clone;
    use array::ArrayTCloneImpl;
    use super::IERC1155Dispatcher;
    use super::IERC1155DispatcherTrait;
    use super::IERC20Dispatcher;
    use super::IERC20DispatcherTrait;
    use instaswap::libraries::upgradeable::Upgradeable;
    use starknet::class_hash::ClassHash;
    use instaswap::libraries::upgradeable::Upgradeable::assert_only_admin;


    use instaswap::libraries::library_erc1155::ERC1155; // TODO: remove when openzeppelin ERC1155 library is supported
    // use openzeppelin::introspection::erc165::ERC165Contract; // TODO: remove when openzeppelin ERC165 library is supported

    use instaswap::libraries::library::AMM;

    #[storage]
    struct Storage {
        currency_address: ContractAddress,
        token_address: ContractAddress,
        currency_reserves: LegacyMap::<u256, u256>,
        token_reserves: LegacyMap::<u256, u256>,
        lp_fee_thousand: u256,
        royalty_fee_thousand: u256,
        royalty_fee_address: ContractAddress,
        lp_total_supplies: LegacyMap::<u256, u256>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        LiquidityAdded: LiquidityAdded,
        LiquidityRemoved: LiquidityRemoved,
        TokensPurchase: TokensPurchase,
        CurrencyPurchase: CurrencyPurchase,
    }

    #[derive(Drop, starknet::Event)]
    struct LiquidityAdded {
        provider: ContractAddress,
        tokenIds: Array<u256>,
        tokenAmounts: Array<u256>,
        currencyAmounts: Array<u256>,
    }

    #[derive(Drop, starknet::Event)]
    struct LiquidityRemoved {
        provider: ContractAddress,
        tokenIds: Array<u256>,
        tokenAmounts: Array<u256>,
        details: Array<LiquidityRemovedEventObj>,
    }

    #[derive(Serde, Drop, starknet::Event)]
    struct LiquidityRemovedEventObj {
        currencyAmount: u256,
        soldTokenNumerator: u256,
        boughtCurrencyNumerator: u256,
        totalSupply: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct TokensPurchase {
        buyer: ContractAddress,
        recipient: ContractAddress,
        tokenBoughtIds: Array<u256>,
        tokenBoughtAmounts: Array<u256>,
        currencySoldAmounts: Array<u256>,
    }

    #[derive(Drop, starknet::Event)]
    struct CurrencyPurchase {
        buyer: ContractAddress,
        recipient: ContractAddress,
        tokenSoldIds: Array<u256>,
        tokenSoldAmounts: Array<u256>,
        currencyBoughtAmounts: Array<u256>,
    }

    //##############
    // CONSTRUCTOR #
    //##############

    #[constructor]
    fn constructor(ref self: ContractState, 
        uri: felt252,
        currency_address_: ContractAddress,
        token_address_: ContractAddress,
        lp_fee_thousand_: u256,
        royalty_fee_thousand_: u256,
        royalty_fee_address_: ContractAddress,
        contract_admin: ContractAddress,
    ) {
        Upgradeable::initializer(contract_admin);
        self.currency_address.write(currency_address_);
        self.token_address.write(token_address_);
        self.lp_fee_thousand.write(lp_fee_thousand_);
        set_royalty_info(ref self, royalty_fee_thousand_, royalty_fee_address_);
        ERC1155::initializer(uri);
    }

    fn upgrade(ref self: ContractState, 
        impl_hash: ClassHash) {
        Upgradeable::_upgrade(impl_hash);
    }

    //#####
    // LP #
    //#####

    fn add_liquidity(ref self: ContractState, 
        mut max_currency_amounts: Array<u256>,
        mut token_ids: Array<u256>,
        mut token_amounts: Array<u256>,
        deadline: felt252,
    ) {
        assert(max_currency_amounts.len() == token_ids.len(), 'not same length 1');
        assert(max_currency_amounts.len() == token_amounts.len(), 'not same length 2');
        let info = starknet::get_block_info().unbox();
        assert(info.block_timestamp < deadline.try_into().unwrap(), 'deadline passed');
        _add_liquidity(ref self, max_currency_amounts, token_ids, token_amounts);
    }

    fn _add_liquidity(ref self: ContractState, 
        mut max_currency_amounts: Array<u256>,
        mut token_ids: Array<u256>,
        mut token_amounts: Array<u256>,
    ) {
        let eventTokenIds: Array<u256> = token_ids.clone();
        let eventTokenAmounts: Array<u256> = token_amounts.clone();
        let mut eventCurrencyAmounts: Array<u256> = ArrayTrait::new();
        loop {
            match max_currency_amounts.pop_front() {
                Option::Some(_) => {
                    let caller = starknet::get_caller_address();
                    let contract = starknet::get_contract_address();
                    let currency_address_ = self.currency_address.read();
                    let token_address_ = self.token_address.read();

                    let currency_reserve_ = self.currency_reserves.read(*token_ids.at(0_usize));
                    let lp_total_supply_ = self.lp_total_supplies.read(*token_ids.at(0_usize));
                    let token_reserve_ = IERC1155Dispatcher {
                        contract_address: token_address_
                    }.balance_of(contract, *token_ids.at(0_usize));

                    let mut lp_total_supply_new_ = 0.into();

                    let mut currency_amount_ = 0.into();
                    if (lp_total_supply_ == 0.into()) {
                        currency_amount_ = *max_currency_amounts.at(0_usize);

                        let square = (*max_currency_amounts.at(0_usize)) * (*token_amounts.at(0_usize));
                        let lp_total_supply_new_felt: felt252 = u256_sqrt(square).into();
                        let lp_total_supply_new_ = lp_total_supply_new_felt.into();
                        let lp_amount_for_lp_ = lp_total_supply_new_ - 1000.into();
                        IERC20Dispatcher {
                            contract_address: currency_address_
                        }.transfer_from(caller, contract, currency_amount_);

                        IERC1155Dispatcher {
                            contract_address: token_address_
                        }.safe_transfer_from(
                            caller,
                            contract,
                            *token_ids.at(0_usize),
                            *token_amounts.at(0_usize),
                            ArrayTrait::new()
                        );

                        ERC1155::_mint(caller, *token_ids.at(0_usize), lp_amount_for_lp_, ArrayTrait::new());

                        // permanently lock the first MINIMUM_LIQUIDITY tokens
                        ERC1155::_mint(
                            contract_address_const::<0>(),
                            *token_ids.at(0_usize),
                            1000.into(),
                            ArrayTrait::new()
                        );
                    } else {
                        // Required price calc
                        // X/Y = dx/dy
                        // dx = X*dy/Y
                        let numerator = currency_reserve_ * (*token_amounts.at(0_usize));
                        let currency_amount_ = numerator / token_reserve_; 
                        assert(currency_amount_ <= *max_currency_amounts.at(0_usize), 'amount too high');

                        // Transfer currency to contract
                        IERC20Dispatcher {
                            contract_address: currency_address_
                        }.transfer_from(caller, contract, currency_amount_);
                        // append to eventCurrencyAmounts for emit event
                        eventCurrencyAmounts.append(currency_amount_);

                        IERC1155Dispatcher {
                            contract_address: token_address_
                        }.safe_transfer_from(
                            caller,
                            contract,
                            *token_ids.at(0_usize),
                            *token_amounts.at(0_usize),
                            ArrayTrait::new()
                        );

                        let lp_amount_ = lp_total_supply_ * currency_amount_ / currency_reserve_;
                        let lp_total_supply_new_ = lp_total_supply_ + lp_amount_;

                        // Mint LP tokens to caller
                        ERC1155::_mint(caller, *token_ids.at(0_usize), lp_amount_, ArrayTrait::new());
                    }

                    // update lp_total_supplies
                    self.lp_total_supplies.write(*token_ids.at(0_usize), lp_total_supply_new_);

                    let new_currency_reserve = currency_reserve_ + currency_amount_;
                    self.currency_reserves.write(*token_ids.at(0_usize), new_currency_reserve);

                    let new_token_reserve = token_reserve_ + *token_amounts.at(0_usize);
                    self.token_reserves.write(*token_ids.at(0_usize), new_token_reserve);

                    self.emit(LiquidityAdded {
                        provider: caller,
                        tokenIds: eventTokenIds.clone(),
                        tokenAmounts: eventTokenAmounts.clone(),
                        currencyAmounts: eventCurrencyAmounts.clone(),
                    });
                    max_currency_amounts.pop_front();
                    token_ids.pop_front();
                    token_amounts.pop_front();
                },
                Option::None(_) => {
                    break ();
                },
            };
        };
        return ;

    }

    fn remove_liquidity(ref self: ContractState, 
        mut min_currency_amounts: Array<u256>,
        mut token_ids: Array<u256>,
        mut min_token_amounts: Array<u256>,
        mut lp_amounts: Array<u256>,
        deadline: felt252,
    ) {
        assert(min_currency_amounts.len() == token_ids.len(), 'not same length 1');
        assert(min_currency_amounts.len() == min_token_amounts.len(), 'not same length 2');
        assert(min_currency_amounts.len() == lp_amounts.len(), 'not same length 3');
        let info = starknet::get_block_info().unbox();
        assert(info.block_timestamp < deadline.try_into().unwrap(), 'deadline passed');
        _remove_liquidity(ref self, 
            min_currency_amounts, token_ids, min_token_amounts, lp_amounts, 
        );
    }

    fn _remove_liquidity(ref self: ContractState, 
        mut min_currency_amounts: Array<u256>,
        mut token_ids: Array<u256>,
        mut min_token_amounts: Array<u256>,
        mut lp_amounts: Array<u256>,
    ) {

        loop {
            match min_currency_amounts.pop_front() {
                Option::Some(_) => {
                    let caller = starknet::get_caller_address();
                    let contract = starknet::get_contract_address();
                    let currency_address_ = self.currency_address.read();
                    let token_address_ = self.token_address.read();

                    let currency_reserve_ = self.currency_reserves.read(*token_ids.at(0_usize));
                    let lp_total_supply_ = self.lp_total_supplies.read(*token_ids.at(0_usize));
                    let token_reserve_ = IERC1155Dispatcher {
                        contract_address: token_address_
                    }.balance_of(contract, *token_ids.at(0_usize));

                    assert(lp_total_supply_ > *lp_amounts.at(0_usize), 'insufficient lp supply');

                    let numerator = currency_reserve_ * (*lp_amounts.at(0_usize));
                    let currency_amount_ = numerator / lp_total_supply_;
                    assert(currency_amount_ >= *min_currency_amounts.at(0_usize), 'amount too low');

                    let numerator = token_reserve_ * (*lp_amounts.at(0_usize));
                    let token_amount_ = numerator / lp_total_supply_;
                    assert(token_amount_ >= *min_token_amounts.at(0_usize), 'amount too low');

                    // Burn LP tokens from caller
                    ERC1155::_burn(caller, *token_ids.at(0_usize), *lp_amounts.at(0_usize));

                    let new_currency_reserve = currency_reserve_ - currency_amount_;
                    self.currency_reserves.write(*token_ids.at(0_usize), new_currency_reserve);

                    let new_token_reserve = token_reserve_ - token_amount_;
                    self.token_reserves.write(*token_ids.at(0_usize), new_token_reserve);

                    let lp_total_supply = lp_total_supply_ - *lp_amounts.at(0_usize);
                    self.lp_total_supplies.write(*token_ids.at(0_usize), lp_total_supply);

                    // Transfer currency to caller
                    IERC20Dispatcher { contract_address: currency_address_ }.transfer(caller, currency_amount_);
                    IERC1155Dispatcher {
                        contract_address: token_address_
                    }.safe_transfer_from(
                        contract, caller, *token_ids.at(0_usize), token_amount_, ArrayTrait::new()
                    );

                    // TODO Emit Event

                    min_currency_amounts.pop_front();
                    token_ids.pop_front();
                    min_token_amounts.pop_front();
                    lp_amounts.pop_front();
                },
                Option::None(_) => {
                    break ();
                },
            };
        };
        
        
    }

    fn _to_rounded_liquidity(self: @ContractState, 
        _token_id: u256,
        _amount_pool: u256,
        _token_reserve: u256,
        _currency_reserve: u256,
        _total_liquidity: u256,
    ) -> (
        u256,
        u256,
        u256,
        u256,
        u256,
    ) {
        let mut currency_numerator: u256 = _amount_pool * _currency_reserve;
        let mut token_numerator: u256 = _amount_pool * _token_reserve;

        // Convert all tokenProduct rest to currency
        let sold_token_numerator = token_numerator % _total_liquidity;

        if sold_token_numerator != 0 {
            // The trade happens "after" funds are out of the pool
            // so we need to remove these funds before computing the rate
            let virtual_token_reserve =
                (_token_reserve - (token_numerator / _total_liquidity)) * _total_liquidity;
            let virtual_currency_reserve =
                (_currency_reserve - (currency_numerator / _total_liquidity)) * _total_liquidity;

            // Skip process if any of the two reserves is left empty
            // this step is important to avoid an error withdrawing all left liquidity
            if virtual_currency_reserve != 0 && virtual_token_reserve != 0 {
                let mut bought_currency_numerator = AMM::get_currency_amount_when_sell(
                    sold_token_numerator,
                    virtual_currency_reserve,
                    virtual_token_reserve,
                    self.lp_fee_thousand.read(),
                );
                let mut royalty_numerator = get_royalty_with_amount(self, bought_currency_numerator);
                bought_currency_numerator -= royalty_numerator;

                currency_numerator += bought_currency_numerator;

                // Add royalty numerator (needs to be converted to ROYALTIES_DENOMINATOR)
                royalty_numerator =
                    royalty_numerator * 1000 / _total_liquidity;

                return (
                    currency_numerator / _total_liquidity,
                    token_numerator / _total_liquidity,
                    sold_token_numerator,
                    bought_currency_numerator,
                    royalty_numerator,
                );
            }
        }

        // Calculate amounts
        (
            currency_numerator / _total_liquidity,
            token_numerator / _total_liquidity,
            0,
            0,
            0,
        )
    }

    //#############
    // BUY TOKENS #
    //#############
    fn buy_tokens(ref self: ContractState, 
        mut max_currency_amounts: Array<u256>,
        mut token_ids: Array<u256>,
        mut token_amounts: Array<u256>,
        deadline: felt252,
    ) -> u256 {
        assert(max_currency_amounts.len() == token_ids.len(), 'not same length 1');
        assert(max_currency_amounts.len() == token_amounts.len(), 'not same length 2');
        let info = starknet::get_block_info().unbox();
        assert(info.block_timestamp < deadline.try_into().unwrap(), 'deadline passed');

        let currency_amount = buy_tokens_loop(ref self, token_ids, token_amounts, );
        assert(currency_amount <= *max_currency_amounts.at(0_usize), 'amount too high');

        return currency_amount;
    }

    fn buy_tokens_loop(ref self: ContractState, mut token_ids: Array<u256>, mut token_amounts: Array<u256>) -> u256 {
        
        if (token_ids.len() == 0_usize) {
            return 0.into();
        }
        let caller = starknet::get_caller_address();
        let contract = starknet::get_contract_address();
        let currency_address_ = self.currency_address.read();
        let token_address_ = self.token_address.read();

        let currency_reserve_ = self.currency_reserves.read(*token_ids.at(0_usize));
        let token_reserve_ = self.token_reserves.read(*token_ids.at(0_usize));

        let lp_fee_thousand_ = self.lp_fee_thousand.read();

        let currency_amount_sans_royal_ = AMM::get_currency_amount_when_buy(
            *token_amounts.at(0_usize), currency_reserve_, token_reserve_, lp_fee_thousand_, 
        );

        let royalty_ = get_royalty_with_amount(@self, currency_amount_sans_royal_, );

        let currency_amount_ = currency_amount_sans_royal_ + royalty_;

        // Update reserve 
        let new_currency_reserve = currency_reserve_ + currency_amount_;
        self.currency_reserves.write(*token_ids.at(0_usize), new_currency_reserve);

        // Transfer currency from caller
        IERC20Dispatcher {
            contract_address: currency_address_
        }.transfer_from(caller, contract, currency_amount_);
        // Royalty transfer
        IERC20Dispatcher {
            contract_address: currency_address_
        }.transfer_from(caller, self.royalty_fee_address.read(), royalty_);

        // Transfer token to caller
        IERC1155Dispatcher {
            contract_address: token_address_
        }.safe_transfer_from(
            contract, caller, *token_ids.at(0_usize), *token_amounts.at(0_usize), ArrayTrait::new()
        );

        // TODO Emit Event

        token_ids.pop_front();
        token_amounts.pop_front();

        let mut currency_total_ = buy_tokens_loop(ref self, token_ids, token_amounts);

        let new_currency_total = currency_total_ + currency_amount_;
        return new_currency_total;
    }

    //##############
    // SELL TOKENS #
    //##############
    fn sell_tokens(ref self: ContractState, 
        mut min_currency_amounts: Array<u256>,
        mut token_ids: Array<u256>,
        mut token_amounts: Array<u256>,
        deadline: felt252,
    ) -> u256 {
        assert(min_currency_amounts.len() == token_ids.len(), 'not same length 1');
        assert(min_currency_amounts.len() == token_amounts.len(), 'not same length 2');
        let info = starknet::get_block_info().unbox();
        assert(info.block_timestamp < deadline.try_into().unwrap(), 'deadline passed');

        let currency_amount = sell_tokens_loop(ref self, token_ids, token_amounts, );
        assert(currency_amount >= *min_currency_amounts.at(0_usize), 'amount too low');

        return currency_amount;
    }

    fn sell_tokens_loop(ref self: ContractState, mut token_ids: Array<u256>, mut token_amounts: Array<u256>) -> u256 {
        
        if (token_ids.len() == 0_usize) {
            return 0.into();
        }
        let caller = starknet::get_caller_address();
        let contract = starknet::get_contract_address();
        let currency_address_ = self.currency_address.read();
        let token_address_ = self.token_address.read();

        let currency_reserve_ = self.currency_reserves.read(*token_ids.at(0_usize));
        let token_reserve_ = self.token_reserves.read(*token_ids.at(0_usize));

        let lp_fee_thousand_ = self.lp_fee_thousand.read();

        let currency_amount_sans_royal_ = AMM::get_currency_amount_when_sell(
            *token_amounts.at(0_usize), currency_reserve_, token_reserve_, lp_fee_thousand_, 
        );

        let royalty_ = get_royalty_with_amount(@self, currency_amount_sans_royal_, );

        let currency_amount_ = currency_amount_sans_royal_ - royalty_;

        // Update reserve
        let new_currency_reserve = currency_reserve_ - currency_amount_;
        self.currency_reserves.write(*token_ids.at(0_usize), new_currency_reserve);

        // Transfer currency to caller
        IERC20Dispatcher { contract_address: currency_address_ }.transfer(caller, currency_amount_);
        // Royalty transfer
        IERC20Dispatcher {
            contract_address: currency_address_
            }.transfer(self.royalty_fee_address.read(), royalty_);

        // Transfer token from caller
        IERC1155Dispatcher {
            contract_address: token_address_
        }.safe_transfer_from(
            caller, contract, *token_ids.at(0_usize), *token_amounts.at(0_usize), ArrayTrait::new()
        );

        // TODO Emit Event

        token_ids.pop_front();
        token_amounts.pop_front();

        let mut currency_total_ = sell_tokens_loop(ref self, token_ids, token_amounts);
        let new_currency_total = currency_total_ + currency_amount_;
        return new_currency_total;
    }

    //################
    // PRICING CALCS #
    //################

    fn get_royalty_with_amount(self: @ContractState, amount_sans_royalty: u256) -> u256 {
        let royalty_fee_thousand_ = self.royalty_fee_thousand.read();
        let royalty = amount_sans_royalty * royalty_fee_thousand_;

        let royalty = royalty / 1000.into();
        return royalty;
    }

    //############
    // RECEIVERS #
    //############

    fn onERC1155Received(ref self: ContractState, 
        operator: ContractAddress,
        from: ContractAddress,
        id: u256,
        value: u256,
        data: Array<felt252>
    ) -> u32 {
        return 0_u32; // TODO: return value
    }

    fn onERC1155BatchReceived(ref self: ContractState, 
        operator: ContractAddress,
        from: ContractAddress,
        ids: Array<u256>,
        values: Array<u256>,
        data: Array<felt252>
    ) -> u32 {
        return 0_u32; // TODO: return value
    }

    //##########
    // Getters #
    //##########

    fn get_currency_address(self: @ContractState) -> ContractAddress {
        return self.currency_address.read();
    }

    fn get_token_address(self: @ContractState) -> ContractAddress {
        return self.token_address.read();
    }

    fn get_currency_reserves(self: @ContractState, token_id: u256) -> u256 {
        return self.currency_reserves.read(token_id);
    }

    fn get_token_reserves(self: @ContractState, token_id: u256) -> u256 {
        return self.token_reserves.read(token_id);
    }

    fn get_lp_fee_thousand(self: @ContractState) -> u256 {
        return self.lp_fee_thousand.read();
    }

    fn get_all_currency_amount_when_sell(self: @ContractState, 
        token_ids: Array<u256>, token_amounts: Array<u256>, 
    ) -> Array<u256> {
        let mut currency_amounts_ = ArrayTrait::new();

        get_all_currency_amount_when_sell_loop(self, token_ids, token_amounts, ref currency_amounts_, );
        return currency_amounts_;
    }

    fn get_all_currency_amount_when_sell_loop(self: @ContractState, 
        mut token_ids: Array<u256>,
        mut token_amounts: Array<u256>,
        ref currency_amounts_: Array<u256>,
    ) {
        
        if (token_ids.len() == 0_usize) {
            return ();
        }
        let currency_reserve_ = self.currency_reserves.read(*token_ids.at(0_usize));
        let token_reserve_ = self.token_reserves.read(*token_ids.at(0_usize));
        let lp_fee_thousand_ = self.lp_fee_thousand.read();
        let currency_amount_sans_royal_ = AMM::get_currency_amount_when_sell(
            *token_amounts.at(0_usize), currency_reserve_, token_reserve_, lp_fee_thousand_, 
        );
        let royalty_ = get_royalty_with_amount(self, currency_amount_sans_royal_, );
        let currency_amount_ = currency_amount_sans_royal_ - royalty_;
        currency_amounts_.append(currency_amount_);
        token_ids.pop_front();
        token_amounts.pop_front();
        get_all_currency_amount_when_sell_loop(self, token_ids, token_amounts, ref currency_amounts_, );
    }

    fn get_all_currency_amount_when_buy(self: @ContractState, 
        token_ids: Array<u256>, token_amounts: Array<u256>, 
    ) -> Array<u256> {
        let mut currency_amounts_ = ArrayTrait::new();

        get_all_currency_amount_when_buy_loop(self, token_ids, token_amounts, ref currency_amounts_, );
        return currency_amounts_;
    }

    fn get_all_currency_amount_when_buy_loop(self: @ContractState, 
        mut token_ids: Array<u256>,
        mut token_amounts: Array<u256>,
        ref currency_amounts_: Array<u256>,
    ) {
        
        if (token_ids.len() == 0_usize) {
            return ();
        }
        let currency_reserve_ = self.currency_reserves.read(*token_ids.at(0_usize));
        let token_reserve_ = self.token_reserves.read(*token_ids.at(0_usize));
        let lp_fee_thousand_ = self.lp_fee_thousand.read();
        let currency_amount_sans_royal_ = AMM::get_currency_amount_when_buy(
            *token_amounts.at(0_usize), currency_reserve_, token_reserve_, lp_fee_thousand_, 
        );
        let royalty_ = get_royalty_with_amount(self, currency_amount_sans_royal_, );

        let currency_amount_ = currency_amount_sans_royal_ - royalty_;
        currency_amounts_.append(currency_amount_);
        token_ids.pop_front();
        token_amounts.pop_front();
        get_all_currency_amount_when_buy_loop(self, token_ids, token_amounts, ref currency_amounts_, );
    }

    //########################
    // ERC1155 for LP tokens #
    //########################

    fn supports_interface(self: @ContractState, interface_id: u32) -> bool {
        // ERC165Contract::supports_interface(interface_id)
        return true; // TODO: need implement base on ERC165
    }


    fn balance_of(self: @ContractState, account: ContractAddress, token_id: u256, ) -> u256 {
        ERC1155::balance_of(account, token_id)
    }

    fn balance_of_batch(self: @ContractState, accounts: Array<ContractAddress>, token_ids: Array<u256>, ) -> Array<u256> {
        ERC1155::balance_of_batch(accounts, token_ids)
    }

    fn is_approved_for_all(self: @ContractState, account: ContractAddress, operator: ContractAddress, ) -> bool {
        ERC1155::is_approved_for_all(account, operator)
    }

    fn uri(self: @ContractState, token_id: u256) -> felt252 {
        return ERC1155::uri(token_id);
    }

    fn owner(self: @ContractState) -> felt252 {
        return Upgradeable::get_admin().into();
    }

    fn get_lp_supply(self: @ContractState, token_id: u256) -> u256 {
        return self.lp_total_supplies.read(token_id);
    }

    //
    // Externals
    //
    fn set_approval_for_all(ref self: ContractState, operator: ContractAddress, approved: bool, ) {
        ERC1155::set_approval_for_all(operator, approved, );
    }

    fn safe_transfer_from(ref self: ContractState, 
        from: ContractAddress,
        to: ContractAddress,
        token_id: u256,
        amount: u256,
        data: Array<felt252>,
    ) {
        ERC1155::safe_transfer_from(from, to, token_id, amount, data, );
    }

    fn safe_batch_transfer_from(ref self: ContractState, 
        from: ContractAddress,
        to: ContractAddress,
        token_ids: Array<u256>,
        amounts: Array<u256>,
        data: Array<felt252>,
    ) {
        ERC1155::safe_batch_transfer_from(from, to, token_ids, amounts, data, );
    }

    //########
    // ADMIN #
    //########
    fn set_royalty_info(ref self: ContractState, royalty_fee_thousand_: u256, royalty_fee_address_: ContractAddress, ) {
        assert_only_admin();

        self.royalty_fee_thousand.write(royalty_fee_thousand_);
        self.royalty_fee_address.write(royalty_fee_address_);
    }

    fn set_lp_info(ref self: ContractState, lp_fee_thousand: u256, ) {
        assert_only_admin();

        self.lp_fee_thousand.write(lp_fee_thousand);
    }
}
