use std::path::PathBuf;
use clap::Parser;
use zisk_sdk::{BuildArgs, ZiskStdin, build_program, build_program_with_args};

fn main() {
    if std::env::var("CARGO_FEATURE_PRECOMPILE").is_ok() {
        let args = BuildArgs::parse_from(["build", "--no-default-features", "-F", "precompile"]);
        build_program_with_args("../guest", args);
    } else {
        build_program("../guest");
    }

    let n = 1000u32;
    let stdin_save = ZiskStdin::new();
    stdin_save.write(&n);
    let path = PathBuf::from("tmp/input.bin");
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent).unwrap();
    }
    stdin_save.save(&path).unwrap();
}
