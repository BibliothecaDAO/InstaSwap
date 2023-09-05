
#[starknet::contract]
mod WERC20FromERC1155 {

    use openzeppelin::token::erc20::erc20::ERC20;
    use openzeppelin::token::erc20::erc20::ERC20::InternalTrait;
    use openzeppelin::token::erc20::interface::IERC20;
    use openzeppelin::token::erc20::interface::IERC20CamelOnly;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use zeroable::Zeroable;

    #[storage]
    struct Storage {

    }

    #[constructor]
    fn constructor(
        ref self: ContractState
    ) {

    }



    // below is from openzeppelin


    //
    // External
    //

    #[external(v0)]
    impl ERC20Impl of IERC20<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            let erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.name()

        }

        fn symbol(self: @ContractState) -> felt252 {
            let erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.symbol()
        }

        fn decimals(self: @ContractState) -> u8 {
            18
        }

        fn total_supply(self: @ContractState) -> u256 {
            let erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.total_supply()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            let erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.balance_of(account)
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress
        ) -> u256 {
            let erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.allowance(owner, spender)
        }

        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let mut erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.transfer(recipient, amount)
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            let mut erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.transfer_from(sender, recipient, amount)
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let mut erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self.approve(spender, amount)
        }
    }

    #[external(v0)]
    impl ERC20CamelOnlyImpl of IERC20CamelOnly<ContractState> {
        fn totalSupply(self: @ContractState) -> u256 {
            ERC20Impl::total_supply(self)
        }

        fn balanceOf(self: @ContractState, account: ContractAddress) -> u256 {
            ERC20Impl::balance_of(self, account)
        }

        fn transferFrom(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256
        ) -> bool {
            ERC20Impl::transfer_from(ref self, sender, recipient, amount)
        }
    }

    #[external(v0)]
    fn increase_allowance(
        ref self: ContractState, spender: ContractAddress, added_value: u256
    ) -> bool {
        let mut erc20_self = ERC20::unsafe_new_contract_state();
        erc20_self._increase_allowance(spender, added_value)
    }

    #[external(v0)]
    fn increaseAllowance(
        ref self: ContractState, spender: ContractAddress, addedValue: u256
    ) -> bool {
        increase_allowance(ref self, spender, addedValue)
    }

    #[external(v0)]
    fn decrease_allowance(
        ref self: ContractState, spender: ContractAddress, subtracted_value: u256
    ) -> bool {
        let mut erc20_self = ERC20::unsafe_new_contract_state();
        erc20_self._decrease_allowance(spender, subtracted_value)
    }

    #[external(v0)]
    fn decreaseAllowance(
        ref self: ContractState, spender: ContractAddress, subtractedValue: u256
    ) -> bool {
        decrease_allowance(ref self, spender, subtractedValue)
    }


}