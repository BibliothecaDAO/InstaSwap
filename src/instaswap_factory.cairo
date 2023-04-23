#[contract]
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

    #[external]
    fn constructor(
        pair_contract_class_hash_: ClassHash,
        lp_fee_thousand_: u256,
        royalty_fee_thousand_: u256,
        royalty_fee_recipient_: ContractAddress,
        contract_admin_: ContractAddress,
    ) {
        lp_fee_thousand::write(lp_fee_thousand_);
        royalty_fee_thousand::write(royalty_fee_thousand_);
        royalty_fee_recipient::write(royalty_fee_recipient_);
        contract_admin::write(contract_admin_);
        pair_contract_class_hash::write(pair_contract_class_hash_);
    }

    #[external]
    fn create_pair(
        token_a: ContractAddress,
        token_b: ContractAddress,
    ) -> ContractAddress {
        assert(token_a.is_non_zero(), 'ZERO_TOKEN_ADDRESS');
        assert(token_b.is_non_zero(), 'ZERO_TOKEN_ADDRESS');
        assert(token_a != token_b, 'IDENTICAL_ADDRESSES');
        let exist_pair = get_pair(token_a, token_b);
        assert(exist_pair.is_non_zero(), 'PAIR_EXISTS');
        // TODO support interface check make token_m to be ERC20, token_n to be ERC1155
        let mut token_m: ContractAddress = token_a;
        let mut token_n: ContractAddress = token_b;

        // TODO hash token_m and token_n
        let salt = 0;

        let mut output = ArrayTrait::new();
        Serde::serialize(ref output, '');
        Serde::serialize(ref output, token_m.into());
        Serde::serialize(ref output, token_n.into());
        Serde::serialize(ref output, lp_fee_thousand::read());
        Serde::serialize(ref output, royalty_fee_thousand::read());
        Serde::serialize(ref output, royalty_fee_recipient::read());
        Serde::serialize(ref output, contract_admin::read().into());
        let mut serialized = output.span();


        let (result_address, result_data) = deploy_syscall(
            pair_contract_class_hash::read(),
            salt,
            serialized,
            false,
        ).unwrap_syscall();

        pair::write((token_m, token_n), result_address);
        // TODO emit Event

        // TODO update pair_num
        return result_address;
    }

    #[view]
    fn get_pair(
        token_a: ContractAddress,
        token_b: ContractAddress,
    ) -> ContractAddress {
        // TODO support interface check make token_m to be ERC20, token_n to be ERC1155
        let mut token_m: ContractAddress = token_a;
        let mut token_n: ContractAddress = token_b;
        return pair::read((token_m, token_n));
    }

    // #[view]
    // fn get_all_pairs() -> Array<ContractAddress> {
    //     //TODO
    // }

    #[view]
    fn get_num_of_pairs() {
        //TODO
    }

    #[view]
    fn get_pair_contract_class_hash() -> ClassHash {
        pair_contract_class_hash::read()
    }


}