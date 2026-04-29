{
  lib,
  rustPlatform,
  stdenv,
  fetchFromGitHub,
  pkg-config,
  oniguruma,
  onnxruntime,
  openssl,
  sqlite,
}:
rustPlatform.buildRustPackage rec {
  pname = "icm";
  version = "0.10.30";
  rev = "ceb6de07a5735e7762f826f3457f6ff01f169d20";

  src = fetchFromGitHub {
    inherit rev;
    owner = "rtk-ai";
    repo = "icm";
    hash = "sha256-wb67icz0IgANQ0gxEGz3Fw87iLnh7crPL+K5ch3HG14=";
  };

  cargoHash = "sha256-mlfuKxxGfZ1b8kCYihY0/MbGYQDWhsZUGoBGiVTIJw8=";
  doCheck = false;

  nativeBuildInputs = [
    pkg-config
  ];

  buildInputs =
    [
      oniguruma
      openssl
      sqlite
    ]
    ++ lib.optionals stdenv.isLinux [onnxruntime];

  env =
    {
      OPENSSL_NO_VENDOR = true;
      RUSTONIG_SYSTEM_LIBONIG = true;
    }
    // lib.optionalAttrs stdenv.isLinux {
      ORT_LIB_LOCATION = "${onnxruntime}/lib";
    };

  meta = {
    description = "Permanent memory for AI agents. Single binary, zero dependencies, MCP native";
    homepage = "https://github.com/rtk-ai/icm";
    license = lib.licenses.asl20;
    mainProgram = pname;
  };
}
