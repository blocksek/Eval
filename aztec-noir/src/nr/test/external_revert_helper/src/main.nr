use aztec::macros::aztec;

#[aztec]
pub contract ExternalRevertHelper {
    use aztec::macros::functions::{external, only_self};

    #[external("private")]
    fn arm_revert() {
        self.enqueue(ExternalRevertHelper::at(self.address).force_revert_public());
    }

    #[external("public")]
    #[only_self]
    fn force_revert_public() {
        assert(false, "external forced revert");
    }
}
