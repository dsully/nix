{pkgs, ...}: let
  inherit (pkgs) buildPackages lib stdenv;
in
  pkgs.buildGoModule rec {
    pname = "gibo";
    version = "3.0.14";

    src = pkgs.fetchFromGitHub {
      owner = "simonwhitaker";
      repo = pname;
      rev = "7f070e68b3bdad989f75f9d819cf7af2c1eca5d4";
      hash = "sha256-+5qPPA1uodKHx7iDmTq0FJ7OP0sw6UD4QxvezUEQzP4=";
    };

    vendorHash = "sha256-3Y4ZCl4avEM2eqh+3IodAudac6Kny0mD/a4aznrfWRE=";
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
