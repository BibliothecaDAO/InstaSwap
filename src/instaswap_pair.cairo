use starknet::ContractAddress;
use array::ArrayTrait;
const SUCCESS: felt252 = 'SUCCESS';
const FAILURE: felt252 = 'FAILURE';

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
    fn transfer_from(
        ref self: TContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
    ) -> bool;
    fn approve(ref self: TContractState, spender: ContractAddress, amount: u256) -> bool;
    fn increase_allowance(
        ref self: TContractState, spender: ContractAddress, added_value: u256
    ) -> bool;
    fn decrease_allowance(
        ref self: TContractState, spender: ContractAddress, subtracted_value: u256
    ) -> bool;
}

#[starknet::interface]
trait IERC1155<TContractState> {
    fn uri(self: @TContractState, token_id: u256) -> Span<felt252>;

    fn supports_interface(self: @TContractState, interface_id: u32) -> bool;

    fn balance_of(self: @TContractState, account: starknet::ContractAddress, id: u256) -> u256;

    fn balance_of_batch(
        self: @TContractState, accounts: Span<starknet::ContractAddress>, ids: Span<u256>
    ) -> Span<u256>;

    fn is_approved_for_all(
        self: @TContractState,
        account: starknet::ContractAddress,
        operator: starknet::ContractAddress
    ) -> bool;

    fn set_approval_for_all(
        ref self: TContractState, operator: starknet::ContractAddress, approved: bool
    );

    fn safe_transfer_from(
        ref self: TContractState,
        from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        id: u256,
        amount: u256,
        data: Span<felt252>
    );

    fn safe_batch_transfer_from(
        ref self: TContractState,
        from: starknet::ContractAddress,
        to: starknet::ContractAddress,
        ids: Span<u256>,
        amounts: Span<u256>,
        data: Span<felt252>
    );
}

#[starknet::interface]
trait IInstaSwapPair<TContractState> {
    fn add_liquidity(
        ref self: TContractState,
        max_currency_amounts: Array<u256>,
        token_ids: Array<u256>,
        token_amounts: Array<u256>,
        deadline: felt252,
    );

    fn remove_liquidity(
        ref self: TContractState,
        min_currency_amounts: Array<u256>,
        token_ids: Array<u256>,
        min_token_amounts: Array<u256>,
        lp_amounts: Array<u256>,
        deadline: felt252,
    );

    fn buy_tokens(
        ref self: TContractState,
        max_currency_amounts: Array<u256>,
        token_ids: Array<u256>,
        token_amounts: Array<u256>,
        deadline: felt252,
    ) -> Array<u256>;

    fn sell_tokens(
        ref self: TContractState,
        min_currency_amounts: Array<u256>,
        token_ids: Array<u256>,
        token_amounts: Array<u256>,
        deadline: felt252,
    ) -> Array<u256>;

    fn get_currency_address(self: @TContractState) -> ContractAddress;

    fn get_token_address(self: @TContractState) -> ContractAddress;

    fn get_currency_reserves(self: @TContractState, token_id: u256) -> u256;

    fn get_token_reserves(self: @TContractState, token_id: u256) -> u256;

    fn get_lp_fee_thousand(self: @TContractState) -> u256;

    fn get_all_currency_amount_when_sell(
        self: @TContractState, token_ids: Array<u256>, token_amounts: Array<u256>, 
    ) -> Array<u256>;

    fn get_all_currency_amount_when_buy(
        self: @TContractState, token_ids: Array<u256>, token_amounts: Array<u256>, 
    ) -> Array<u256>;

    fn get_royalty_fee_thousand(self: @TContractState) -> u256;

    fn get_royalty_fee_address(self: @TContractState) -> ContractAddress;

    fn get_lp_supply(self: @TContractState, token_id: u256) -> u256;

    fn set_royalty_info(
            ref self: TContractState, royalty_fee_thousand_: u256, royalty_fee_address_: ContractAddress, 
        );

    fn set_lp_info(ref self: TContractState, lp_fee_thousand: u256);

    fn upgrade(ref self: TContractState, new_implementation: starknet::ClassHash);
}

#[starknet::contract]
mod InstaSwapPair {
    use rules_erc1155::erc1155::interface;
    use array::{ SpanTrait, SpanSerde, ArrayTrait};
    use rules_utils::introspection::interface::ISRC5;

    use zeroable::Zeroable;
    use starknet::get_caller_address;
    use starknet::contract_address_const;
    use starknet::ContractAddress;
    use starknet::ContractAddressIntoFelt252;
    use dict::Felt252DictTrait;
    use option::OptionTrait;
    use option::OptionTraitImpl;
    use core::ec;
    use core::traits::TryInto;
    use core::traits::Into;
    use box::BoxTrait;
    use clone::Clone;
    use debug::PrintTrait;
    use array::ArrayTCloneImpl;
    use super::IERC1155Dispatcher;
    use super::IERC1155DispatcherTrait;
    use super::IERC20Dispatcher;
    use super::IERC20DispatcherTrait;
    use starknet::class_hash::ClassHash;
    use rules_erc1155::erc1155::erc1155;
    use rules_erc1155::erc1155::erc1155::ERC1155;
    use rules_erc1155::erc1155::erc1155::ERC1155::{InternalTrait as ERC1155HelperTrait};
    use rules_erc1155::erc1155::interface::{IERC1155, IERC1155Metadata};
    use rules_utils::introspection::src5::SRC5;
    use rules_utils::introspection::src5::SRC5::{InternalTrait as SRC5HelperTrait};

    use rules_tokens::access::ownable;
    use rules_tokens::access::ownable::{Ownable, IOwnable};
    use rules_tokens::access::ownable::Ownable::{
        InternalTrait as OwnableHelperTrait, ModifierTrait as OwnableModifierTrait
    };

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
        TokensSale: TokensSale,
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
        tokenBoughtIds: Array<u256>,
        tokenBoughtAmounts: Array<u256>,
        currencySoldAmounts: Array<u256>,
    }

    #[derive(Drop, starknet::Event)]
    struct TokensSale {
        seller: ContractAddress,
        tokenSoldIds: Array<u256>,
        tokenSoldAmounts: Array<u256>,
        currencyBoughtAmounts: Array<u256>,
    }

    //##############
    // CONSTRUCTOR #
    //##############

    #[constructor]
    fn constructor(
        ref self: ContractState,
        uri: Span<felt252>,
        currency_address_: ContractAddress,
        token_address_: ContractAddress,
        lp_fee_thousand_: u256,
        royalty_fee_thousand_: u256,
        royalty_fee_address_: ContractAddress,
        contract_admin: ContractAddress,
    ) {
        self.currency_address.write(currency_address_);
        self.token_address.write(token_address_);
        self.lp_fee_thousand.write(lp_fee_thousand_);
        let mut ownable_self = Ownable::unsafe_new_contract_state();

        ownable_self.initializer();
        ownable_self._transfer_ownership(contract_admin);

        // because set_royalty_info will() check owner, and the caller contract may not be owner, so we have to set royalty info here 
        self.royalty_fee_thousand.write(royalty_fee_thousand_);
        self.royalty_fee_address.write(royalty_fee_address_);

        let mut erc1155_self = ERC1155::unsafe_new_contract_state();
        erc1155_self.initializer(uri_: uri);

        let mut src5_self = SRC5::unsafe_new_contract_state();
        src5_self._register_interface(interface::IERC1155_RECEIVER_ID);
    }

    #[external(v0)]
    impl IInstaSwapPairImpl of super::IInstaSwapPair<ContractState> {
        //#####
        // LP #
        //#####

        fn add_liquidity(
            ref self: ContractState,
            max_currency_amounts: Array<u256>,
            token_ids: Array<u256>,
            token_amounts: Array<u256>,
            deadline: felt252,
        ) {
            assert(max_currency_amounts.len() == token_ids.len(), 'not same length 1');
            assert(max_currency_amounts.len() == token_amounts.len(), 'not same length 2');
            let info = starknet::get_block_info().unbox();
            assert(info.block_timestamp < deadline.try_into().unwrap(), 'deadline passed');
            _add_liquidity(ref self, max_currency_amounts, token_ids, token_amounts);
        }

        fn remove_liquidity(
            ref self: ContractState,
            min_currency_amounts: Array<u256>,
            token_ids: Array<u256>,
            min_token_amounts: Array<u256>,
            lp_amounts: Array<u256>,
            deadline: felt252,
        ) {
            assert(min_currency_amounts.len() == token_ids.len(), 'not same length 1');
            assert(min_currency_amounts.len() == min_token_amounts.len(), 'not same length 2');
            assert(min_currency_amounts.len() == lp_amounts.len(), 'not same length 3');
            let info = starknet::get_block_info().unbox();
            assert(info.block_timestamp < deadline.try_into().unwrap(), 'deadline passed');
            _remove_liquidity(
                ref self, min_currency_amounts, token_ids, min_token_amounts, lp_amounts, 
            );
        }

        //#############
        // BUY TOKENS #
        //#############
        fn buy_tokens(
            ref self: ContractState,
            max_currency_amounts: Array<u256>,
            token_ids: Array<u256>,
            token_amounts: Array<u256>,
            deadline: felt252,
        ) -> Array<u256> {
            assert(max_currency_amounts.len() == token_ids.len(), 'not same length 1');
            assert(max_currency_amounts.len() == token_amounts.len(), 'not same length 2');
            let info = starknet::get_block_info().unbox();
            assert(info.block_timestamp < deadline.try_into().unwrap(), 'deadline passed');

            let currency_amounts = _buy_tokens(
                ref self, max_currency_amounts, token_ids, token_amounts
            );
            return currency_amounts;
        }

        //##############
        // SELL TOKENS #
        //##############
        fn sell_tokens(
            ref self: ContractState,
            min_currency_amounts: Array<u256>,
            token_ids: Array<u256>,
            token_amounts: Array<u256>,
            deadline: felt252,
        ) -> Array<u256> {
            assert(min_currency_amounts.len() == token_ids.len(), 'not same length 1');
            assert(min_currency_amounts.len() == token_amounts.len(), 'not same length 2');
            let info = starknet::get_block_info().unbox();
            assert(info.block_timestamp < deadline.try_into().unwrap(), 'deadline passed');

            let currency_amount = _sell_tokens(
                ref self, min_currency_amounts, token_ids, token_amounts, 
            );
            return currency_amount;
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

        fn get_all_currency_amount_when_sell(
            self: @ContractState, token_ids: Array<u256>, token_amounts: Array<u256>, 
        ) -> Array<u256> {
            let mut currency_amounts_ = ArrayTrait::new();

            get_all_currency_amount_when_sell_loop(
                self, token_ids, token_amounts, ref currency_amounts_, 
            );
            return currency_amounts_;
        }

        fn get_all_currency_amount_when_buy(
            self: @ContractState, token_ids: Array<u256>, token_amounts: Array<u256>, 
        ) -> Array<u256> {
            let mut currency_amounts_ = ArrayTrait::new();

            get_all_currency_amount_when_buy_loop(
                self, token_ids, token_amounts, ref currency_amounts_, 
            );
            return currency_amounts_;
        }

        fn get_royalty_fee_thousand(self: @ContractState) -> u256 {
            return self.royalty_fee_thousand.read();
        }

        fn get_royalty_fee_address(self: @ContractState) -> ContractAddress {
            return self.royalty_fee_address.read();
        }

        fn get_lp_supply(self: @ContractState, token_id: u256) -> u256 {
            return self.lp_total_supplies.read(token_id);
        }

        //########
        // ADMIN #
        //########
        fn set_royalty_info(
            ref self: ContractState, royalty_fee_thousand_: u256, royalty_fee_address_: ContractAddress, 
        ) {
            self._only_owner();

            self.royalty_fee_thousand.write(royalty_fee_thousand_);
            self.royalty_fee_address.write(royalty_fee_address_);
        }

        fn set_lp_info(ref self: ContractState, lp_fee_thousand: u256) {
            self._only_owner();

            self.lp_fee_thousand.write(lp_fee_thousand);
        }

        fn upgrade(ref self: ContractState, new_implementation: starknet::ClassHash) {
            // Modifiers
            self._only_owner();

            // Body
            self._upgrade(:new_implementation);
        }
    }


    fn _add_liquidity(
        ref self: ContractState,
        max_currency_amounts_in: Array<u256>,
        token_ids_in: Array<u256>,
        token_amounts_in: Array<u256>,
    ) {
        let mut max_currency_amounts: Array<u256> = max_currency_amounts_in.clone();
        let mut token_ids: Array<u256> = token_ids_in.clone();
        let mut token_amounts: Array<u256> = token_amounts_in.clone();

        let eventTokenIds: Array<u256> = token_ids.clone();
        let eventTokenAmounts: Array<u256> = token_amounts.clone();
        let mut eventCurrencyAmounts: Array<u256> = ArrayTrait::new();

        let mut erc1155_self = ERC1155::unsafe_new_contract_state();

        loop {
            match max_currency_amounts.pop_front() {
                Option::Some(max_currency_amount) => {
                    let token_id = *token_ids.at(0_usize);
                    let token_amount = *token_amounts.at(0_usize);

                    let caller = starknet::get_caller_address();
                    let contract = starknet::get_contract_address();
                    let currency_address_ = self.currency_address.read();
                    let token_address_ = self.token_address.read();
                    let currency_reserve_ = self.currency_reserves.read(token_id);
                    let mut lp_total_supply_ = self.lp_total_supplies.read(token_id);
                    let token_reserve_ = IERC1155Dispatcher {
                        contract_address: token_address_
                    }.balance_of(contract, token_id);
                    let mut lp_total_supply_new_: u256 = 0_u256;

                    let mut currency_amount_ = 0.into();
                    if (lp_total_supply_ == 0.into()) {
                        currency_amount_ = max_currency_amount;

                        lp_total_supply_new_ = u256_sqrt((max_currency_amount) * (token_amount)).into();
                        let lp_amount_for_lp_ = lp_total_supply_new_ - 1000_u256;

                        IERC20Dispatcher {
                            contract_address: currency_address_
                        }.transfer_from(caller, contract, currency_amount_);
                        IERC1155Dispatcher {
                            contract_address: token_address_
                        }
                            .safe_transfer_from(
                                caller, contract, token_id, token_amount, array![super::SUCCESS].span()
                            );

                        erc1155_self
                            ._mint(caller, token_id, lp_amount_for_lp_, array![super::SUCCESS].span());
                        let (ids, amounts) = erc1155_self._as_singleton_spans(token_id, 1000_u256);

                        // permanently lock the first MINIMUM_LIQUIDITY tokens, since _mint not support mint to zero address, we have to do it manually
                        erc1155_self
                            ._update(Zeroable::zero(),
                                contract_address_const::<0>(),
                                ids,
                                amounts,
                                array![super::SUCCESS].span()
                            );

                        eventCurrencyAmounts.append(currency_amount_);
                    } else {
                        // Required price calc
                        // X/Y = dx/dy
                        // dx = X*dy/Y
                        let numerator = currency_reserve_ * (token_amount);
                        let currency_amount_ = numerator / token_reserve_;
                        assert(currency_amount_ <= max_currency_amount, 'amount too high');
                        // Transfer currency to contract
                        IERC20Dispatcher {
                            contract_address: currency_address_
                        }.transfer_from(caller, contract, currency_amount_);
                        // append to eventCurrencyAmounts for emit event
                        eventCurrencyAmounts.append(currency_amount_);

                        IERC1155Dispatcher {
                            contract_address: token_address_
                        }
                            .safe_transfer_from(
                                caller, contract, token_id, token_amount, array![super::SUCCESS].span()
                            );

                        let lp_amount_ = lp_total_supply_ * currency_amount_ / currency_reserve_;
                        let lp_total_supply_new_ = lp_total_supply_ + lp_amount_;

                        // Mint LP tokens to caller
                        erc1155_self._mint(caller, token_id, lp_amount_, array![super::SUCCESS].span());
                        eventCurrencyAmounts.append(currency_amount_);
                    }
                    // update lp_total_supplies
                    self.lp_total_supplies.write(token_id, lp_total_supply_new_);

                    let new_currency_reserve = currency_reserve_ + currency_amount_;
                    self.currency_reserves.write(token_id, new_currency_reserve);

                    let new_token_reserve = token_reserve_ + token_amount;
                    self.token_reserves.write(token_id, new_token_reserve);

                    token_ids.pop_front();
                    token_amounts.pop_front();
                },
                Option::None(_) => {
                    break ();
                },
            };
        };
        self
            .emit(
                LiquidityAdded {
                    provider: starknet::get_caller_address(),
                    tokenIds: eventTokenIds,
                    tokenAmounts: eventTokenAmounts,
                    currencyAmounts: eventCurrencyAmounts,
                }
            );
        return;
    }


    fn _remove_liquidity(
        ref self: ContractState,
        min_currency_amounts_in: Array<u256>,
        token_ids_in: Array<u256>,
        min_token_amounts_in: Array<u256>,
        lp_amounts_in: Array<u256>,
    ) {
        let mut min_currency_amounts: Array<u256> = min_currency_amounts_in.clone();
        let mut token_ids: Array<u256> = token_ids_in.clone();
        let mut min_token_amounts: Array<u256> = min_token_amounts_in.clone();
        let mut lp_amounts: Array<u256> = lp_amounts_in.clone();
        let eventTokenIds: Array<u256> = token_ids.clone();
        let mut eventTokenAmounts: Array<u256> = ArrayTrait::new();
        let mut eventObjs: Array<LiquidityRemovedEventObj> = ArrayTrait::new();
        let mut erc1155_self = ERC1155::unsafe_new_contract_state();

        loop {
            match min_currency_amounts.pop_front() {
                Option::Some(min_currency_amount) => {
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

                    // using _to_rounded_liquidity()
                    let (
                        currency_amount_,
                        token_amount_,
                        sold_token_numerator,
                        bought_currency_numerator,
                        royalty_numerator
                    ) =
                        _to_rounded_liquidity(
                        ref self,
                        *token_ids.at(0_usize),
                        *lp_amounts.at(0_usize),
                        token_reserve_,
                        currency_reserve_,
                        lp_total_supply_,
                    );
                    assert(currency_amount_ >= min_currency_amount, 'insufficient currency amount');

                    let eventObj = LiquidityRemovedEventObj {
                        currencyAmount: currency_amount_,
                        soldTokenNumerator: sold_token_numerator,
                        boughtCurrencyNumerator: bought_currency_numerator,
                        totalSupply: lp_total_supply_,
                    };
                    eventObjs.append(eventObj);
                    eventTokenAmounts.append(token_amount_);

                    // Burn LP tokens from caller
                    erc1155_self._burn(caller, *token_ids.at(0_usize), *lp_amounts.at(0_usize));

                    let new_currency_reserve = currency_reserve_ - currency_amount_;
                    self.currency_reserves.write(*token_ids.at(0_usize), new_currency_reserve);

                    let new_token_reserve = token_reserve_ - token_amount_;
                    self.token_reserves.write(*token_ids.at(0_usize), new_token_reserve);

                    let lp_total_supply = lp_total_supply_ - *lp_amounts.at(0_usize);
                    self.lp_total_supplies.write(*token_ids.at(0_usize), lp_total_supply);

                    // Transfer currency to caller
                    IERC20Dispatcher {
                        contract_address: currency_address_
                    }.transfer(caller, currency_amount_);

                    IERC1155Dispatcher {
                        contract_address: token_address_
                    }
                        .safe_transfer_from(
                            contract,
                            caller,
                            *token_ids.at(0_usize),
                            token_amount_,
                            array![super::SUCCESS].span()
                        );

                    token_ids.pop_front();
                    min_token_amounts.pop_front();
                    lp_amounts.pop_front();
                },
                Option::None(_) => {
                    break ();
                },
            };
        };

        self
            .emit(
                LiquidityRemoved {
                    provider: starknet::get_caller_address(),
                    tokenIds: eventTokenIds,
                    tokenAmounts: eventTokenAmounts,
                    details: eventObjs,
                }
            );
    }

    fn _to_rounded_liquidity(
        ref self: ContractState,
        _token_id: u256,
        _amount_pool: u256,
        _token_reserve: u256,
        _currency_reserve: u256,
        _total_liquidity: u256,
    ) -> (u256, u256, u256, u256, u256) {
        let mut currency_numerator: u256 = _amount_pool * _currency_reserve;
        let mut token_numerator: u256 = _amount_pool * _token_reserve;

        // Convert all tokenProduct rest to currency
        let sold_token_numerator = token_numerator % _total_liquidity;

        if sold_token_numerator != 0 {
            // The trade happens "after" funds are out of the pool
            // so we need to remove these funds before computing the rate
            let virtual_token_reserve = (_token_reserve - (token_numerator / _total_liquidity))
                * _total_liquidity;
            let virtual_currency_reserve = (_currency_reserve
                - (currency_numerator / _total_liquidity))
                * _total_liquidity;

            // Skip process if any of the two reserves is left empty
            // this step is important to avoid an error withdrawing all left liquidity
            if virtual_currency_reserve != 0 && virtual_token_reserve != 0 {
                let mut bought_currency_numerator = AMM::get_currency_amount_when_sell(
                    sold_token_numerator,
                    virtual_currency_reserve,
                    virtual_token_reserve,
                    self.lp_fee_thousand.read(),
                );
                let mut royalty_numerator = get_royalty_with_amount(
                    self.royalty_fee_thousand.read(), bought_currency_numerator
                );
                bought_currency_numerator -= royalty_numerator;

                currency_numerator += bought_currency_numerator;

                // Add royalty numerator (needs to be converted to ROYALTIES_DENOMINATOR)
                royalty_numerator = royalty_numerator * 1000 / _total_liquidity;

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
        (currency_numerator / _total_liquidity, token_numerator / _total_liquidity, 0, 0, 0)
    }


    fn _buy_tokens(
        ref self: ContractState,
        max_currency_amounts_in: Array<u256>,
        token_ids_in: Array<u256>,
        token_amounts_in: Array<u256>
    ) -> Array<u256> {
        let mut max_currency_amounts: Array<u256> = max_currency_amounts_in.clone();
        let mut token_ids: Array<u256> = token_ids_in.clone();
        let mut token_amounts: Array<u256> = token_amounts_in.clone();
        let eventTokenIds: Array<u256> = token_ids.clone();
        let eventTokenAmounts: Array<u256> = token_amounts.clone();
        let mut currencyAmounts: Array<u256> = ArrayTrait::new();
        loop {
            match max_currency_amounts.pop_front() {
                Option::Some(max_currency_amount) => {
                    let caller = starknet::get_caller_address();
                    let contract = starknet::get_contract_address();
                    let currency_address_ = self.currency_address.read();
                    let token_address_ = self.token_address.read();

                    let currency_reserve_ = self.currency_reserves.read(*token_ids.at(0_usize));
                    let token_reserve_ = self.token_reserves.read(*token_ids.at(0_usize));

                    let lp_fee_thousand_ = self.lp_fee_thousand.read();

                    let currency_amount_sans_royal_ = AMM::get_currency_amount_when_buy(
                        *token_amounts.at(0_usize),
                        currency_reserve_,
                        token_reserve_,
                        lp_fee_thousand_,
                    );

                    let royalty_ = get_royalty_with_amount(
                        self.royalty_fee_thousand.read(), currency_amount_sans_royal_
                    );

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
                    }
                        .safe_transfer_from(
                            contract,
                            caller,
                            *token_ids.at(0_usize),
                            *token_amounts.at(0_usize),
                            array![super::SUCCESS].span()
                        );
                    currencyAmounts.append(currency_amount_);

                    token_ids.pop_front();
                    token_amounts.pop_front();
                },
                Option::None(_) => {
                    break ();
                },
            };
        };
        // Emit event
        self
            .emit(
                TokensPurchase {
                    buyer: starknet::get_caller_address(),
                    tokenBoughtIds: eventTokenIds,
                    tokenBoughtAmounts: eventTokenAmounts,
                    currencySoldAmounts: currencyAmounts.clone(),
                }
            );
        return currencyAmounts;
    }


    fn _sell_tokens(
        ref self: ContractState,
        min_currency_amounts_in: Array<u256>,
        token_ids_in: Array<u256>,
        token_amounts_in: Array<u256>
    ) -> Array<u256> {
        let mut min_currency_amounts: Array<u256> = min_currency_amounts_in.clone();
        let mut token_ids: Array<u256> = token_ids_in.clone();
        let mut token_amounts: Array<u256> = token_amounts_in.clone();
        let eventTokenIds: Array<u256> = token_ids.clone();
        let eventTokenAmounts: Array<u256> = token_amounts.clone();
        let mut currencyAmounts: Array<u256> = ArrayTrait::new();
        loop {
            match min_currency_amounts.pop_front() {
                Option::Some(max_currency_amount) => {
                    let caller = starknet::get_caller_address();
                    let contract = starknet::get_contract_address();
                    let currency_address_ = self.currency_address.read();
                    let token_address_ = self.token_address.read();

                    let currency_reserve_ = self.currency_reserves.read(*token_ids.at(0_usize));
                    let token_reserve_ = self.token_reserves.read(*token_ids.at(0_usize));

                    let lp_fee_thousand_ = self.lp_fee_thousand.read();

                    let currency_amount_sans_royal_ = AMM::get_currency_amount_when_sell(
                        *token_amounts.at(0_usize),
                        currency_reserve_,
                        token_reserve_,
                        lp_fee_thousand_,
                    );

                    let royalty_ = get_royalty_with_amount(
                        self.royalty_fee_thousand.read(), currency_amount_sans_royal_
                    );

                    let currency_amount_ = currency_amount_sans_royal_ - royalty_;

                    // Update reserve
                    let new_currency_reserve = currency_reserve_ - currency_amount_;
                    self.currency_reserves.write(*token_ids.at(0_usize), new_currency_reserve);

                    // Transfer currency to caller
                    IERC20Dispatcher {
                        contract_address: currency_address_
                    }.transfer(caller, currency_amount_);
                    // Royalty transfer
                    IERC20Dispatcher {
                        contract_address: currency_address_
                    }.transfer(self.royalty_fee_address.read(), royalty_);

                    // Transfer token from caller
                    IERC1155Dispatcher {
                        contract_address: token_address_
                    }
                        .safe_transfer_from(
                            caller,
                            contract,
                            *token_ids.at(0_usize),
                            *token_amounts.at(0_usize),
                            array![super::SUCCESS].span()
                        );
                    currencyAmounts.append(currency_amount_);

                    token_ids.pop_front();
                    token_amounts.pop_front();
                },
                Option::None(_) => {
                    break ();
                },
            };
        };
        // Emit event
        self
            .emit(
                TokensSale {
                    seller: starknet::get_caller_address(),
                    tokenSoldIds: eventTokenIds,
                    tokenSoldAmounts: eventTokenAmounts,
                    currencyBoughtAmounts: currencyAmounts.clone(),
                }
            );
        return currencyAmounts;
    }

    //################
    // PRICING CALCS #
    //################

    fn get_royalty_with_amount(royalty_fee_thousand: u256, amount_sans_royalty: u256) -> u256 {
        let royalty = amount_sans_royalty * royalty_fee_thousand;

        let royalty = royalty / 1000.into();
        return royalty;
    }


    fn get_all_currency_amount_when_sell_loop(
        self: @ContractState,
        token_ids_in: Array<u256>,
        token_amounts_in: Array<u256>,
        ref currency_amounts_: Array<u256>,
    ) {
        let mut token_ids: Array<u256> = token_ids_in.clone();
        let mut token_amounts: Array<u256> = token_amounts_in.clone();
        if (token_ids.len() == 0_usize) {
            return ();
        }
        let currency_reserve_ = self.currency_reserves.read(*token_ids.at(0_usize));
        let token_reserve_ = self.token_reserves.read(*token_ids.at(0_usize));
        let lp_fee_thousand_ = self.lp_fee_thousand.read();
        let currency_amount_sans_royal_ = AMM::get_currency_amount_when_sell(
            *token_amounts.at(0_usize), currency_reserve_, token_reserve_, lp_fee_thousand_, 
        );
        let royalty_ = get_royalty_with_amount(
            self.royalty_fee_thousand.read(), currency_amount_sans_royal_
        );
        let currency_amount_ = currency_amount_sans_royal_ - royalty_;
        currency_amounts_.append(currency_amount_);
        token_ids.pop_front();
        token_amounts.pop_front();
        get_all_currency_amount_when_sell_loop(
            self, token_ids, token_amounts, ref currency_amounts_, 
        );
    }


    fn get_all_currency_amount_when_buy_loop(
        self: @ContractState,
        token_ids_in: Array<u256>,
        token_amounts_in: Array<u256>,
        ref currency_amounts_: Array<u256>,
    ) {
        let mut token_ids: Array<u256> = token_ids_in.clone();
        let mut token_amounts: Array<u256> = token_amounts_in.clone();
        if (token_ids.len() == 0_usize) {
            return ();
        }
        let currency_reserve_ = self.currency_reserves.read(*token_ids.at(0_usize));
        let token_reserve_ = self.token_reserves.read(*token_ids.at(0_usize));
        let lp_fee_thousand_ = self.lp_fee_thousand.read();
        let currency_amount_sans_royal_ = AMM::get_currency_amount_when_buy(
            *token_amounts.at(0_usize), currency_reserve_, token_reserve_, lp_fee_thousand_, 
        );
        let royalty_ = get_royalty_with_amount(
            self.royalty_fee_thousand.read(), currency_amount_sans_royal_
        );

        let currency_amount_ = currency_amount_sans_royal_ - royalty_;
        currency_amounts_.append(currency_amount_);
        token_ids.pop_front();
        token_amounts.pop_front();
        get_all_currency_amount_when_buy_loop(
            self, token_ids, token_amounts, ref currency_amounts_, 
        );
    }

    //########################
    // ERC1155 for LP tokens #
    //########################
    //
    // IERC1155 impl
    //

    #[external(v0)]
    impl IERC1155Impl of erc1155::ERC1155ABI<ContractState> {
        // IERC1155

        fn uri(self: @ContractState, token_id: u256) -> Span<felt252> {
            let erc1155_self = ERC1155::unsafe_new_contract_state();

            erc1155_self.uri(:token_id)
        }

        fn balance_of(self: @ContractState, account: starknet::ContractAddress, id: u256) -> u256 {
            let erc1155_self = ERC1155::unsafe_new_contract_state();

            erc1155_self.balance_of(:account, :id)
        }

        fn balance_of_batch(
            self: @ContractState, accounts: Span<starknet::ContractAddress>, ids: Span<u256>
        ) -> Span<u256> {
            let erc1155_self = ERC1155::unsafe_new_contract_state();

            erc1155_self.balance_of_batch(:accounts, :ids)
        }

        fn is_approved_for_all(
            self: @ContractState,
            account: starknet::ContractAddress,
            operator: starknet::ContractAddress
        ) -> bool {
            let erc1155_self = ERC1155::unsafe_new_contract_state();

            erc1155_self.is_approved_for_all(:account, :operator)
        }

        fn set_approval_for_all(
            ref self: ContractState, operator: starknet::ContractAddress, approved: bool
        ) {
            let mut erc1155_self = ERC1155::unsafe_new_contract_state();

            erc1155_self.set_approval_for_all(:operator, :approved);
        }

        fn safe_transfer_from(
            ref self: ContractState,
            from: starknet::ContractAddress,
            to: starknet::ContractAddress,
            id: u256,
            amount: u256,
            data: Span<felt252>
        ) {
            let mut erc1155_self = ERC1155::unsafe_new_contract_state();

            erc1155_self.safe_transfer_from(:from, :to, :id, :amount, :data);
        }

        fn safe_batch_transfer_from(
            ref self: ContractState,
            from: starknet::ContractAddress,
            to: starknet::ContractAddress,
            ids: Span<u256>,
            amounts: Span<u256>,
            data: Span<felt252>
        ) {
            let mut erc1155_self = ERC1155::unsafe_new_contract_state();

            erc1155_self.safe_batch_transfer_from(:from, :to, :ids, :amounts, :data);
        }

        // IERC165

        fn supports_interface(self: @ContractState, interface_id: felt252) -> bool {
            let mut erc1155_self = ERC1155::unsafe_new_contract_state();
            erc1155_self.supports_interface(:interface_id)
        }
    }

    //
    // Ownable impl
    //

    #[external(v0)]
    impl IOwnableImpl of ownable::IOwnable<ContractState> {
        fn owner(self: @ContractState) -> starknet::ContractAddress {
            let ownable_self = Ownable::unsafe_new_contract_state();

            ownable_self.owner()
        }

        fn transfer_ownership(ref self: ContractState, new_owner: starknet::ContractAddress) {
            let mut ownable_self = Ownable::unsafe_new_contract_state();

            ownable_self.transfer_ownership(:new_owner);
        }

        fn renounce_ownership(ref self: ContractState) {
            let mut ownable_self = Ownable::unsafe_new_contract_state();

            ownable_self.renounce_ownership();
        }
    }





    #[generate_trait]
    impl ModifierImpl of ModifierTrait {
        fn _only_owner(self: @ContractState) {
            let ownable_self = Ownable::unsafe_new_contract_state();

            ownable_self.assert_only_owner();
        }
    }

    #[generate_trait]
    impl HelperImpl of HelperTrait {
        fn _upgrade(ref self: ContractState, new_implementation: starknet::ClassHash) {
            starknet::replace_class_syscall(new_implementation);
        }
    }

  #[external(v0)]
  impl ERC1155ReceiverImpl of interface::IERC1155Receiver<ContractState> {
    fn on_erc1155_received(
      ref self: ContractState,
      operator: starknet::ContractAddress,
      from: starknet::ContractAddress,
      id: u256,
      value: u256,
      data: Span<felt252>
    ) -> felt252 {
      if (*data.at(0) == super::SUCCESS) {
        interface::ON_ERC1155_RECEIVED_SELECTOR
      } else {
        0
      }
    }

    fn on_erc1155_batch_received(
      ref self: ContractState,
      operator: starknet::ContractAddress,
      from: starknet::ContractAddress,
      ids: Span<u256>,
      values: Span<u256>,
      data: Span<felt252>
    ) -> felt252 {
      if (*data.at(0) == super::SUCCESS) {
        interface::ON_ERC1155_BATCH_RECEIVED_SELECTOR
      } else {
        0
      }
    }
  }
}
