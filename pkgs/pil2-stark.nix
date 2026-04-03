# Pre-build pil2-stark with libstarks.a so proofman-starks-lib-c's build.rs
# finds the library and skips C++ compilation.
{
  stdenv,
  proofmanSrc,
  pkg-config,
  nasm,
  gmp,
  libsodium,
  nlohmann_json,
  openssl,
  mpi,
  llvmPackages,
}:
stdenv.mkDerivation {
  pname = "pil2-stark";
  version = "0.16.1";

  src = "${proofmanSrc}/pil2-stark";

  nativeBuildInputs = [pkg-config nasm];
  buildInputs = [gmp libsodium nlohmann_json openssl mpi llvmPackages.openmp];

  postPatch = ''
    # Patch C++ headers missing <cstdint> include
    for f in \
      src/rapidsnark/binfile_utils.hpp \
      src/rapidsnark/thread_utils.hpp \
      src/rapidsnark/binfile_writer.hpp
    do
      sed -i '1i #include <cstdint>' "$f"
    done
  '';

  buildPhase = ''
    make -j starks_lib
  '';

  # Output a minimal pil2-stark tree: just what build.rs checks for
  installPhase = ''
    mkdir -p $out/.git $out/lib/include
    cp lib/libstarks.a $out/lib/
    cp lib/include/starks_lib.h $out/lib/include/
  '';
}
