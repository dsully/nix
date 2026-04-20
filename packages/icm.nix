{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  oniguruma,
  openssl,
  sqlite,
}:
rustPlatform.buildRustPackage rec {
  pname = "icm";
  version = "0.10.26";
  rev = "47943d7cf044dc7e6b95f3b9edb32f8147daeddb";

  src = fetchFromGitHub {
    inherit rev;
    owner = "rtk-ai";
    repo = "icm";
    hash = "sha256-XLMv7jQ6nKzwguDfuDwceIxGMvmKvj8j39hh5sudJ00=";
  };

  cargoHash = "sha256-zLDdgXpeLTLM4KRJntXjAt8v3o6+CB8+3UwJSM1LQuk=";
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs = [
    oniguruma
    openssl
    sqlite
  ];

  env = {
    OPENSSL_NO_VENDOR = true;
    RUSTONIG_SYSTEM_LIBONIG = true;
  };

  meta = {
    description = "Permanent memory for AI agents. Single binary, zero dependencies, MCP native";
    homepage = "https://github.com/rtk-ai/icm";
    license = lib.licenses.asl20;
    mainProgram = pname;
  };
}
