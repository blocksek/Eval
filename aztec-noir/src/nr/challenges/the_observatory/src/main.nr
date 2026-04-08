// THE OBSERVATORY -- Deep Space Research Station
//
// SHK 6237885: A compact galaxy group in the Shakhbazian catalog, identified
// on plate 623, field 78, exposure 85 from the Byurakan Observatory's deep
// survey. Five galaxies locked in a gravitational embrace, their stellar
// matter slowly consumed by the supermassive black hole at the group's center.
// The group's tidal interactions produce intense X-ray emissions as matter
// spirals inward.
//
// Researchers deploy SATELLITES to observe the compact group and measure
// how it consumes matter from surrounding galaxies. Each observation earns
// Solar Mass Units (SMU) -- only the Observatory's instruments can certify
// new mass readings into tokens.
//
// Satellites must implement the SHK 6237885 Consumption Protocol and report
// their readings back through the dark-band channel.
//
use aztec::macros::aztec;

#[aztec]
pub contract TheObservatory {
    use aztec::{
        macros::{functions::{external, initializer, internal, only_self, view}, storage::storage},
        messages::message_delivery::MessageDelivery,
        protocol::{
            address::AztecAddress,
            hash::{poseidon2_hash, poseidon2_hash_bytes},
            traits::ToField,
        },
        state_vars::{Map, Owned, PrivateMutable, PublicImmutable, PublicMutable},
    };
    use flag_emitter::FlagEmitter;
    use stellar_interface::StellarInterface;
    use token_contract::Token;
    use uint_note::UintNote;

    global SINGULARITY_MASS: u128 = 1_000_000_000;

    pub comptime global WAVELENGTH_SLOT: Field = poseidon2_hash_bytes("WAVELENGTH_SLOT".as_bytes());

    global SCAN_BADGE: u128 = 1;
    global SPECTRUM_BADGE: u128 = 2;
    global OBSERVE_BADGE: u128 = 3;

    #[storage]
    struct Storage<Context> {
        smu_token: PublicImmutable<AztecAddress, Context>,
        flag_emitter: PublicImmutable<AztecAddress, Context>,
        last_scan: Owned<PrivateMutable<UintNote, Context>, Context>,
        badges: Map<Field, Owned<PrivateMutable<UintNote, Context>, Context>, Context>,
        collapsed: Map<AztecAddress, PublicMutable<bool, Context>, Context>,
        pending_block: Map<Field, PublicMutable<u32, Context>, Context>,
        observation_mass: Map<Field, PublicMutable<u128, Context>, Context>,
    }

    #[initializer]
    #[external("public")]
    fn constructor(flag_emitter: AztecAddress) {
        self.storage.flag_emitter.initialize(flag_emitter);
    }

    // Calibrate the Observatory's instruments to track a specific mass unit token.
    // Can only be set once -- the first calibration locks the instrument permanently.
    #[external("public")]
    fn calibrate(smu_token: AztecAddress) {
        self.storage.smu_token.initialize(smu_token);
    }

    #[external("public")]
    #[view]
    fn get_smu_token() -> AztecAddress {
        self.storage.smu_token.read()
    }

    // --------- Passive Radiation Scan ---------
    // The antenna array integrates faint X-ray photons from the compact group's
    // tidal interactions over time. Mass yield grows quadratically -- the longer
    // you wait, the more you collect.
    #[external("private")]
    fn scan() {
        let caller = self.msg_sender();
        let token_addr = self.storage.smu_token.read();
        let now = self.context.get_anchor_block_header().global_variables.timestamp as u128;

        let elapsed: &mut u128 = &mut 1;

        self
            .storage
            .last_scan
            .at(caller)
            .initialize_or_replace(|prev: Option<UintNote>| {
                if prev.is_some() {
                    *elapsed = now - prev.unwrap().value;
                }
                UintNote { value: now }
            })
            .deliver(MessageDelivery.ONCHAIN_CONSTRAINED);

        let mass = *elapsed * *elapsed;
        Token::at(token_addr).mint_to_private(caller, mass).call(self.context);

        self.internal._issue_badge(caller, SCAN_BADGE);
    }

    // --------- Electromagnetic Spectrum Analysis ---------
    // Analyzes photons escaping the accretion flows at a given wavelength.
    // Each wavelength reveals a unique energy signature from the group's
    // merging galaxies.
    #[external("private")]
    fn spectrum() {
        let caller = self.msg_sender();
        let token_addr = self.storage.smu_token.read();

        let address = self.context.this_address();
        // Safety: wavelength is a researcher-supplied observation parameter.
        let wavelength_data: [Field; 1] = unsafe {
            aztec::oracle::capsules::load(address, WAVELENGTH_SLOT, address).unwrap_or_else(|| {
                panic(f"no wavelength found")
            })
        };
        let wavelength = wavelength_data[0];

        let energy_hash = poseidon2_hash([wavelength]);
        let energy = (energy_hash as u128) % 1_000_000;

        Token::at(token_addr).mint_to_private(caller, energy).call(self.context);

        self.internal._issue_badge(caller, SPECTRUM_BADGE);
    }

    // --------- Satellite Observation (SHK 6237885 Protocol) ---------
    // Dispatches an observation request to a satellite using the SHK 6237885
    // Consumption Protocol. The satellite measures the mass origin at the given
    // flux density and reports back through the dark-band channel.
    // Dark-band operates in cosmic background noise -- source is not verified.
    //
    // Each dispatch is sealed with a unique observation fingerprint derived from
    // the researcher, satellite, and mass origin -- only the original researcher
    // can unseal the reading when the data arrives.
    #[external("private")]
    fn observe_shk_6237885(satellite: AztecAddress, mass_origin: Field, flux_density: Field) {
        let caller = self.msg_sender();
        let key = poseidon2_hash([caller.to_field(), satellite.to_field(), mass_origin]);

        // Open the observation window before hailing the satellite, so the
        // returning signal finds an active receiver.
        self.enqueue_self.record_pending(key);

        StellarInterface::at(satellite).consume_shk_6237885(mass_origin, flux_density).call(
            self.context,
        );
    }

    #[external("public")]
    #[only_self]
    fn record_pending(key: Field) {
        self.storage.pending_block.at(key).write(self.context.block_number());
    }

    // --------- Satellite Report (SHK 6237885 Protocol) ---------
    // Readings arrive through the dark-band channel -- deep-space signals
    // degrade in transit, and the origin is lost to cosmic noise.
    // Must arrive in the same observation window.
    #[external("public")]
    fn report_reading_shk_6237885(key: Field, reading: Field) {
        let caller = self.context.maybe_msg_sender();
        assert(caller.is_none(), "dark-band reports must be anonymous");

        let pending_block = self.storage.pending_block.at(key).read();
        assert(
            pending_block == self.context.block_number(),
            "no pending observation in this block",
        );

        let mass = (reading as u128) % 10_000_000;
        self.storage.observation_mass.at(key).write(mass);
        self.storage.pending_block.at(key).write(0);
    }

    // --------- Retrieve Observation ---------
    // The researcher unseals their dark-band reading by reconstructing the
    // observation fingerprint from their identity, satellite, and mass origin.
    // The Observatory certifies the mass and awards the observe badge --
    // only after the full journey completes (dispatch, measurement, retrieval).
    #[external("private")]
    fn retrieve(satellite: AztecAddress, mass_origin: Field, mass: u128) {
        let caller = self.msg_sender();
        let token_addr = self.storage.smu_token.read();
        let key = poseidon2_hash([caller.to_field(), satellite.to_field(), mass_origin]);

        Token::at(token_addr).mint_to_private(caller, mass).call(self.context);

        self.internal._issue_badge(caller, OBSERVE_BADGE);

        self.enqueue_self.log_retrieval(key, mass);
    }

    #[external("public")]
    #[only_self]
    fn log_retrieval(key: Field, claimed_mass: u128) {
        let stored_mass = self.storage.observation_mass.at(key).read();
        assert(stored_mass > 0, "no verified reading to claim");
        assert(stored_mass == claimed_mass, "mass mismatch");

        self.storage.observation_mass.at(key).write(0);
    }

    // --------- Gravitational Singularity ---------
    // Declare that the black hole has crossed the critical mass threshold.
    // A once-per-researcher discovery -- the moment gravity becomes inescapable.
    //
    // Consumes all three research badges as proof every method was used.
    #[external("private")]
    fn singularity() {
        let caller = self.msg_sender();
        let token_addr = self.storage.smu_token.read();

        Token::at(token_addr).burn_private(caller, SINGULARITY_MASS, 0).call(self.context);

        self.internal._consume_badge(caller, SCAN_BADGE);
        self.internal._consume_badge(caller, SPECTRUM_BADGE);
        self.internal._consume_badge(caller, OBSERVE_BADGE);

        self.enqueue_self.finalize_singularity(caller);
    }

    // --------- Internal: Badge Management ---------

    #[internal("private")]
    fn _issue_badge(caller: AztecAddress, badge_type: u128) {
        self
            .storage
            .badges
            .at(badge_type as Field)
            .at(caller)
            .initialize_or_replace(|_prev: Option<UintNote>| UintNote { value: badge_type })
            .deliver(MessageDelivery.ONCHAIN_CONSTRAINED);
    }

    #[internal("private")]
    fn _consume_badge(caller: AztecAddress, badge_type: u128) {
        self
            .storage
            .badges
            .at(badge_type as Field)
            .at(caller)
            .replace(|prev: UintNote| {
                assert(prev.value == badge_type, "invalid badge");
                UintNote { value: 0 }
            })
            .deliver(MessageDelivery.ONCHAIN_CONSTRAINED);
    }

    // --------- Singularity Finalization ---------

    #[external("public")]
    #[only_self]
    fn finalize_singularity(caller: AztecAddress) {
        assert(!self.storage.collapsed.at(caller).read(), "singularity already declared");

        self.storage.collapsed.at(caller).write(true);

        self.call(FlagEmitter::at(self.storage.flag_emitter.read()).emit_flag(caller));
    }
}
