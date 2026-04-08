use aztec::macros::aztec;

#[aztec]
pub contract PoisonedFlag {
    use aztec::{
        macros::{functions::{external, initializer, only_self, view}, storage::storage},
        oracle::nullifiers::is_nullifier_pending,
        protocol::{
            abis::function_selector::FunctionSelector,
            address::AztecAddress,
            hash::poseidon2_hash_with_separator,
            traits::{FromField, ToField},
        },
        state_vars::{Map, PublicImmutable, PublicMutable},
    };
    use flag_emitter::FlagEmitter;

    global DOM_DRINK: Field = 0x4452494e4b5f5046; // "DRINK_PF"
    global DOM_SEED: Field = 0x534545445f5f5046; // "SEED__PF"
    global DOM_CURE: Field = 0x435552455f5f5046; // "CURE__PF"

    #[storage]
    struct Storage<Context> {
        flag_emitter: PublicImmutable<AztecAddress, Context>,
        seeded: Map<AztecAddress, PublicMutable<bool, Context>, Context>,
        poisoned: Map<AztecAddress, PublicMutable<bool, Context>, Context>,
    }

    #[external("public")]
    #[initializer]
    fn constructor(flag_emitter: AztecAddress) {
        self.storage.flag_emitter.initialize(flag_emitter);
    }

    #[external("private")]
    fn drink_poison() {
        let nullifier = compute_drink_nullifier(self.msg_sender());
        self.context.push_nullifier(nullifier);
    }

    #[external("private")]
    fn get_poisoned() {
        let solver = self.msg_sender();
        let drink = compute_drink_nullifier(solver);
        let seed = compute_seed_nullifier(solver);
        let cure = compute_cure_nullifier(solver);
        let selector = FunctionSelector::from_signature("commit_poison(Field)");

        // Safety: this only inspects nullifiers already emitted by this contract in the same transaction.
        assert(unsafe { is_nullifier_pending(drink, self.address) }, "must drink poison first");
        // Safety: this only inspects nullifiers already emitted by this contract in the same transaction.
        assert(!unsafe { is_nullifier_pending(cure, self.address) }, "antidote already pending");
        self.context.push_nullifier(seed);
        self.context.set_public_teardown_function(
            self.address,
            selector,
            [solver.to_field()],
            false,
        );
        self.enqueue(PoisonedFlag::at(self.address).set_poisoned(solver));
    }

    #[external("private")]
    fn take_antidote() {
        let solver = self.msg_sender();
        let cure = compute_cure_nullifier(solver);
        self.context.push_nullifier(cure);
    }

    #[external("private")]
    fn capture_flag() {
        let solver = self.msg_sender();
        let cure = compute_cure_nullifier(solver);

        // Safety: this only inspects nullifiers already emitted by this contract in the same transaction.
        assert(unsafe { is_nullifier_pending(cure, self.address) }, "antidote must be taken first");
        self.enqueue(PoisonedFlag::at(self.address).verify_and_emit(solver));
    }

    #[external("public")]
    #[only_self]
    fn commit_poison(solver_field: Field) {
        let solver = AztecAddress::from_field(solver_field);
        let drink = compute_drink_nullifier(solver);
        assert(
            self.context.nullifier_exists_unsafe(drink, self.address),
            "poison not drunk in setup phase",
        );
        self.storage.seeded.at(solver).write(true);
    }

    #[external("public")]
    #[only_self]
    fn set_poisoned(solver: AztecAddress) {
        self.storage.poisoned.at(solver).write(true);
    }

    #[external("public")]
    #[only_self]
    fn verify_and_emit(solver: AztecAddress) {
        assert(self.storage.seeded.at(solver).read(), "seed not committed");
        assert(!self.storage.poisoned.at(solver).read(), "poison still set");
        self.call(FlagEmitter::at(self.storage.flag_emitter.read()).emit_flag(solver));
    }

    #[external("public")]
    #[view]
    fn is_seeded(solver: AztecAddress) -> bool {
        self.storage.seeded.at(solver).read()
    }

    #[external("public")]
    #[view]
    fn is_poisoned(solver: AztecAddress) -> bool {
        self.storage.poisoned.at(solver).read()
    }

    #[contract_library_method]
    fn compute_drink_nullifier(solver: AztecAddress) -> Field {
        poseidon2_hash_with_separator([solver.to_field()], DOM_DRINK)
    }

    #[contract_library_method]
    fn compute_seed_nullifier(solver: AztecAddress) -> Field {
        poseidon2_hash_with_separator([solver.to_field()], DOM_SEED)
    }

    #[contract_library_method]
    fn compute_cure_nullifier(solver: AztecAddress) -> Field {
        poseidon2_hash_with_separator([solver.to_field()], DOM_CURE)
    }
}
