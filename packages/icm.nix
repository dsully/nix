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
  version = "0.10.28";
  rev = "b8b33b8261832d1963f98e65897bd1c0438105cd";

  src = fetchFromGitHub {
    inherit rev;
    owner = "rtk-ai";
    repo = "icm";
    hash = "sha256-THPlYzqybM7czoIdY5+Q4JNz0QtPdi4ypZtF1xwnIe4=";
  };

  cargoHash = "sha256-JkibswGbsxCQwqf+HoOYvSJaaAJwrKhLi3P17eHzmeU=";
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
