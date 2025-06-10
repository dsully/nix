{pkgs, ...}: let
  inherit (pkgs) buildPackages lib stdenv;
in
  pkgs.buildGoModule rec {
    pname = "gibo";
    version = "3.0.14";

    src = pkgs.fetchFromGitHub {
      owner = "simonwhitaker";
      repo = "gibo";
      rev = "df8ff667b98085ea9d8ef6433d11c5f0d817049f";
      hash = "sha256-6w+qhwOHkfKt0hgKO98L6Si0RNJN+CXOOFzGlvxFjcA=";
    };

    vendorHash = "sha256-pD+7yvBydg1+BQFP0G8rRYTCO//Wg/6pzY19DLs42Gk=";

    ldflags = [
      "-s"
      "-w"
      "-X=github.com/simonwhitaker/gibo/cmd.version=${version}"
    ];

    nativeBuildInputs = [
      pkgs.installShellFiles
    ];

    postInstall = lib.optionalString (stdenv.hostPlatform.emulatorAvailable buildPackages) (
      let
        emulator = stdenv.hostPlatform.emulator buildPackages;
      in ''
        installShellCompletion --cmd gibo \
          --bash <(${emulator} $out/bin/gibo completion bash) \
          --fish <(${emulator} $out/bin/gibo completion fish) \
          --zsh <(${emulator} $out/bin/gibo completion zsh)
      ''
    );

    meta = {
      description = "Easy access to gitignore boilerplates";
      homepage = "https://github.com/simonwhitaker/gibo";
      license = lib.licenses.unlicense;
      mainProgram = pname;
    };
  }
