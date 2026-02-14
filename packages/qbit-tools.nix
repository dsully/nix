{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage {
    pname = "qbit-tools";
    version = "0.3.10";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = "qbit-tools";
      rev = "3d7df9ca71a4e9780dec0d4388c48d13783acbf1";
      hash = "sha256-0/WeLQYNm6Cgz8ZTHNeGooMUmxMdAhwFUcQQYCWowMI=";
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
