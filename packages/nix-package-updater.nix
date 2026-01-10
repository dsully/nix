{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "nix-package-updater";
    version = "0.5.1";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = pname;
      rev = "e96f1536d1aa99d2269d033061bd6ae4fb622bea";
      hash = "sha256-zGgVfrbdLyrt+s1xAJRJRJYxcX58H4Ddyj8g/sd2UYQ=";
    };

    cargoHash = "sha256-6IWzRDbhD04eCugAtaPfRDxMj6l9dfslYSp/Jl+qiDw=";

    nativeBuildInputs = [
      installShellFiles
      pkg-config
    ];

    buildInputs = [
      libgit2
      openssl
      zlib
    ];

    postInstall = lib.optionalString (stdenv.hostPlatform.emulatorAvailable buildPackages) (
      let
        emulator = stdenv.hostPlatform.emulator buildPackages;
      in ''
        installShellCompletion --cmd ${pname} \
          --bash <(${emulator} $out/bin/${pname} --completions bash) \
          --fish <(${emulator} $out/bin/${pname} --completions fish) \
          --zsh <(${emulator} $out/bin/${pname} --completions zsh)
      ''
    );

    meta = {
      description = "Update Nix Packages";
      homepage = "https://github.com/dsully/nix-package-updater";
      license = lib.licenses.mit;
      mainProgram = pname;
    };
  }
