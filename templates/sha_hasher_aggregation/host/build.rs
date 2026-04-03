use clap::Parser;
use zisk_sdk::{BuildArgs, build_program, build_program_with_args};

fn main() {
    if std::env::var("CARGO_FEATURE_PRECOMPILE").is_ok() {
        let args = BuildArgs::parse_from(["build", "--no-default-features", "-F", "precompile"]);
        build_program_with_args("../guest", args);
    } else {
        build_program("../guest");
    }
    build_program("../guest_agg");
}
