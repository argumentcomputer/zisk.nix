rec {
  sha_hasher = {
    path = ./sha_hasher;
    description = "SHA-256 Hasher";
  };
  default = sha_hasher;
}
