use aztec::macros::aztec;

#[aztec]
contract SummonersDeckSolver {
    use aztec::macros::functions::external;
    use aztec::protocol::address::AztecAddress;
    use summoners_deck::SummonersDeck;

    #[external("private")]
    fn invoke(target: AztecAddress, reader: AztecAddress, nonce: Field) {
        SummonersDeck::at(target).summon(reader, nonce).call(self.context);
    }
}
