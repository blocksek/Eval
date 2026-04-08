// Stellar Interface -- SHK 6237885 Consumption Protocol
//
// consume_shk_6237885(mass_origin, flux_density):
//   mass_origin   -- identifier of the mass source being consumed (Field)
//   flux_density  -- measured energy flux of the consumption event (Field)
//
use aztec::macros::aztec;

#[aztec]
pub contract StellarInterface {
    use aztec::macros::functions::external;

    // Record a consumption event from the compact group -- the mass origin
    // identifies the infalling source and the flux density captures the
    // measured intensity. Satellites implement this to perform measurements;
    // the Observatory's instruments use the same protocol to certify readings.
    #[external("private")]
    fn consume_shk_6237885(mass_origin: Field, flux_density: Field) {
        // Reference implementation -- no-op.
    }
}
