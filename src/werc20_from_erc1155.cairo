
#[starknet::interface]
trait BriqToken<TContractState> {

    fn name(self: @TContractState) -> felt252;

    fn symbol(self: @TContractState) -> felt252;

    fn balanceOfMaterial_(ref self: TContractState, owner: felt252, material: felt252) -> felt252;

    fn transferFT_(ref self: TContractState, sender: felt252, recipient: felt252, material: felt252, qty: felt252);
}
#[starknet::contract]
mod WERC20FromERC1155 {

    use openzeppelin::token::erc20::erc20::ERC20;
    use openzeppelin::token::erc20::erc20::ERC20::InternalTrait;
    use openzeppelin::token::erc20::interface::IERC20;
    use openzeppelin::token::erc20::interface::IERC20CamelOnly;
    use starknet::ContractAddress;
    use starknet::{ get_caller_address, get_contract_address};
    use zeroable::Zeroable;
    use super::{BriqToken, BriqTokenDispatcher, BriqTokenDispatcherTrait};
    // use instaswap::erc1155::{IERC1155, IERC1155Dispatcher, IERC1155DispatcherTrait};

    #[storage]
    struct Storage {
        erc1155_address: ContractAddress,
        token_id: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        erc1155_address: ContractAddress,
        token_id: u256,
    ) {
        self.erc1155_address.write(erc1155_address);
        self.token_id.write(token_id);

        let erc1155 = BriqTokenDispatcher { contract_address: erc1155_address };

        let mut erc20_self = ERC20::unsafe_new_contract_state();
        erc20_self.initializer('w' + erc1155.name(), 'w' + erc1155.symbol());
    }

    #[external(v0)]
    #[generate_trait]
    impl WrapImpl of Wrap {
        fn deposit(ref self: ContractState, amount: u256) {
            assert(amount > 0, 'Not positive');
            let mut erc1155 = BriqTokenDispatcher { contract_address: self.erc1155_address.read() };
            erc1155.transferFT_(get_caller_address().into(), get_contract_address().into(), self.token_id.read().try_into().unwrap(), amount.try_into().unwrap());
            let mut erc20_self = ERC20::unsafe_new_contract_state();
            erc20_self._mint(get_caller_address(), amount);

        }

        fn withdraw(ref self: ContractState) {

        }
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