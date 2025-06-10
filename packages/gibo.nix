{pkgs, ...}: let
  inherit (pkgs) buildPackages lib stdenv;
in
  pkgs.buildGoModule rec {
    pname = "gibo";
    version = "3.0.14";

    src = pkgs.fetchFromGitHub {
      owner = "simonwhitaker";
      repo = "gibo";
      # Keep at this rev until Nix has go 1.24.4+
      rev = "ad7f4a114a30eea01cf52bf49cd52c9fd5eb87e1";
      hash = "sha256-AC6PtEMJV92kw+8BrOOsHLxVvirBpkOdahgSHrrunaY=";
    };

    vendorHash = "sha256-pD+7yvBydg1+BQFP0G8rRYTCO//Wg/6pzY19DLs42Gk=";
    doCheck = false;

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
