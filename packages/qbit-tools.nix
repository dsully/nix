{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "qbit-tools";
    version = "0.3.10";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = "qbit-tools";
      rev = "673b9344759cba8f1e474d31df302a2903c6becd";
      hash = "sha256-cx6YFDO1YsnNHnqHt+qagLt40dFW3EDpG7w0fF+Cp2g=";
    };

    cargoHash = "sha256-NbZu74lo+qQFIXSldLmGQJzG8B4DZw9/L4oPsW70Vq8=";
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
