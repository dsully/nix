{
  lib,
  buildPackages,
  rustPlatform,
  fetchFromGitHub,
  installShellFiles,
  pkg-config,
  openssl,
  stdenv,
}:
rustPlatform.buildRustPackage {
  pname = "qbit-tools";
  version = "0.3.11";

  src = fetchFromGitHub {
    owner = "dsully";
    repo = "qbit-tools";
    rev = "5ea3f6fc7cd615ba1714640ef55416e06cc05396";
    hash = "sha256-5LxXt3gxemtnaHscuYgKdic0tMWyDZ2E7lVjxeXsv/U=";
  };

  cargoHash = "sha256-UtJbBhnIkaF0Y+J+L7Bnz58Hlc5beOiEddWTNhKLpLU=";
  doCheck = false;

  nativeBuildInputs =
    [
      installShellFiles
    ]
    ++ lib.optionals stdenv.isLinux [
      pkg-config
    ];

  buildInputs = lib.optionals stdenv.isLinux [
    openssl
  ];

  postInstall = lib.optionalString (stdenv.hostPlatform.emulatorAvailable buildPackages) (
    let
      emulator = stdenv.hostPlatform.emulator buildPackages;
      tool = "stash-tool";
    in ''
      installShellCompletion --cmd ${tool} \
        --bash <(${emulator} $out/bin/${tool} completions bash) \
        --fish <(${emulator} $out/bin/${tool} completions fish) \
        --zsh <(${emulator} $out/bin/${tool} completions zsh)
    ''
  );

  meta = {
    description = "QB Tools";
    homepage = "https://github.com/dsully/qbit-tools.git";
    mainProgram = "qbit-status";
  };
}
