use anyhow::Result;
use host::GUEST;
use zisk_sdk::{EmuOptions, ziskemu};

fn main() -> Result<()> {
    let stdin = host::sha_stdin(100, [0u8; 32]);

    println!("Running ZisK Emulator on SHA-hasher guest...");
    let emu_options = EmuOptions {
        log_output: true,
        ..EmuOptions::default()
    };
    ziskemu(&GUEST, stdin, &emu_options)?;
    println!("ZisK Emulator completed successfully!");

    Ok(())
}
