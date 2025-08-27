{pkgs, ...}: let
  inherit (pkgs) buildPackages lib stdenv;
in
  pkgs.buildGoModule rec {
    pname = "gibo";
    version = "3.0.14";

    src = pkgs.fetchFromGitHub {
      owner = "simonwhitaker";
      repo = pname;
      rev = "e0aceb7d60a3f2dd2151c2ca81bc18531d6f66aa";
      hash = "sha256-w+vQE97GHeOLJzPWZSJBaFAJvmXU6u3ivpxleV7Eo0I=";
    };

    vendorHash = "";
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
