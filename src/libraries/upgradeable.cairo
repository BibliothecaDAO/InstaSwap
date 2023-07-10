#[starknet::contract]
mod Upgradeable {
    use starknet::class_hash::ClassHash;
    use starknet::class_hash::ClassHashZeroable;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::syscalls::replace_class_syscall;
    use zeroable::Zeroable;

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        Upgraded: Upgraded,
        AdminChanged: AdminChanged,
    }

    #[derive(Drop, starknet::Event)]
    struct Upgraded {
        implementation: ClassHash
    }

    #[storage]
    struct Storage {
        admin: ContractAddress,
        initialized: bool,
    }

    #[derive(Drop, starknet::Event)]
    struct AdminChanged {
        previous_admin: ContractAddress, new_admin: ContractAddress
    }

    fn initializer(ref self: ContractState, contract_admin: ContractAddress) {
        assert(!self.initialized.read(), 'Contract already initialized');
        self.initialized.write(true);
        _set_admin(ref self, contract_admin);
    }

    fn assert_only_admin(self: @ContractState) {
        let caller: ContractAddress = get_caller_address();
        let admin: ContractAddress = self.admin.read();
        assert(caller == admin, 'Caller is not admin');
    }

    fn get_admin(self: @ContractState) -> ContractAddress {
        self.admin.read()
    }

    //
    // Unprotected
    //

    fn _set_admin(ref self: ContractState, new_admin: ContractAddress) {
        assert(!new_admin.is_zero(), 'Admin cannot be zero');
        let old_admin: ContractAddress = self.admin.read();
        self.admin.write(new_admin);
        self.emit(AdminChanged {previous_admin: old_admin, new_admin: new_admin});
    }

    fn _upgrade(ref self: ContractState, impl_hash: ClassHash) {
        assert(!impl_hash.is_zero(), 'Class hash cannot be zero');
        replace_class_syscall(impl_hash);
        self.emit(Upgraded {implementation: impl_hash});
    }
}
