{
  lib,
  buildPackages,
  rustPlatform,
  installShellFiles,
  pkg-config,
  openssl,
  stdenv,
}:
rustPlatform.buildRustPackage {
  pname = "qbit-tools";
  version = "0.3.12";

  src = fetchGit {
    url = "git+ssh://git@github.com/dsully/qbit-tools";
    rev = "ae721e2a36aec5c97409cb8706556dc8cdbf953d";
  };

  cargoHash = "sha256-Z1vTr+1baeB8wV1CSqT48SA6LMYfmugk+maA4RBuPao=";
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
