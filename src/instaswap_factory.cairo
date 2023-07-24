#[starknet::contract]
mod InstaSwapFactory {
    use zeroable::Zeroable;
    use starknet::syscalls::deploy_syscall;
    use array::ArrayTrait;
    use array::SpanTrait;
    use starknet::ContractAddress;
    use starknet::ContractAddressIntoFelt252;
    use traits::Into;
    use serde::Serde;
    use option::OptionTrait;
    use starknet::class_hash::ClassHash;

    #[storage]
    struct Storage {
        pair_contract_class_hash: ClassHash,
        contract_admin: ContractAddress,
        pair: LegacyMap::<(ContractAddress, ContractAddress), ContractAddress>,
        lp_fee_thousand: u256,
        royalty_fee_thousand: u256,
        royalty_fee_recipient: ContractAddress,
    }

    //##############
    // CONSTRUCTOR #
    //##############

    #[constructor]
    fn constructor(
        ref self: ContractState,
        pair_contract_class_hash_: ClassHash,
        lp_fee_thousand_: u256,
        royalty_fee_thousand_: u256,
        royalty_fee_recipient_: ContractAddress,
        contract_admin_: ContractAddress,
    ) {
        self.lp_fee_thousand.write(lp_fee_thousand_);
        self.royalty_fee_thousand.write(royalty_fee_thousand_);
        self.royalty_fee_recipient.write(royalty_fee_recipient_);
        self.contract_admin.write(contract_admin_);
        self.pair_contract_class_hash.write(pair_contract_class_hash_);
    }

    fn create_pair(
        ref self: ContractState, token_a: ContractAddress, token_b: ContractAddress, 
    ) -> ContractAddress {
        assert(token_a.is_non_zero(), 'ZERO_TOKEN_ADDRESS');
        assert(token_b.is_non_zero(), 'ZERO_TOKEN_ADDRESS');
        assert(token_a != token_b, 'IDENTICAL_ADDRESSES');
        let exist_pair = get_pair(@self, token_a, token_b);
        assert(exist_pair.is_non_zero(), 'PAIR_EXISTS');
        // TODO support interface check make token_m to be ERC20, token_n to be ERC1155
        let mut token_m: ContractAddress = token_a;
        let mut token_n: ContractAddress = token_b;

        // TODO hash token_m and token_n
        let salt = 0;

        let mut output = ArrayTrait::new();
        let uri = '';
        uri.serialize(ref output);
        token_m.serialize(ref output);
        token_n.serialize(ref output);
        self.lp_fee_thousand.read().serialize(ref output);
        self.royalty_fee_thousand.read().serialize(ref output);
        self.royalty_fee_recipient.read().serialize(ref output);
        self.contract_admin.read().serialize(ref output);
        let mut serialized = output.span();

        let (result_address, result_data) = deploy_syscall(
            self.pair_contract_class_hash.read(), salt, serialized, false, 
        )
            .unwrap_syscall();

        self.pair.write((token_m, token_n), result_address);
        // TODO emit Event

        // TODO update pair_num
        return result_address;
    }

    fn get_pair(
        self: @ContractState, token_a: ContractAddress, token_b: ContractAddress, 
    ) -> ContractAddress {
        // TODO support interface check make token_m to be ERC20, token_n to be ERC1155
        let mut token_m: ContractAddress = token_a;
        let mut token_n: ContractAddress = token_b;
        return self.pair.read((token_m, token_n));
    }

    // #[view]
    // fn get_all_pairs() -> Array<ContractAddress> {
    //     //TODO
    // }

    fn get_num_of_pairs(self: @ContractState, ) { //TODO
    }

    fn get_pair_contract_class_hash(self: @ContractState) -> ClassHash {
        self.pair_contract_class_hash.read()
    }
}
