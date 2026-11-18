{
  lib,
  rustPlatform,
  installShellFiles,
  pkg-config,
  openssl,
  stdenv,
  emptyFile,
}:
if stdenv.hostPlatform.isLinux
then
  rustPlatform.buildRustPackage {
    pname = "qbit-tools";
    version = "0.4.3";

    src = fetchGit {
      url = "git+ssh://git@github.com/dsully/qbit-tools";
      rev = "022e51c5a8ca8f1c259a34c5f314c436fe4b7387";
    };

    cargoHash = "sha256-Xr7aRUceBR0POo2Hse+sss3agkZJg7YB1VqekoOTMBA=";
    doCheck = false;

    nativeBuildInputs = [
      installShellFiles
      pkg-config
    ];

    buildInputs = [
      openssl
    ];

    postInstall = let
      tool = "stash-tool";
    in ''
      installShellCompletion --cmd ${tool} \
        --bash <($out/bin/${tool} completions bash) \
        --fish <($out/bin/${tool} completions fish) \
        --zsh <($out/bin/${tool} completions zsh)
    '';

    meta = {
      description = "QB Tools";
      homepage = "https://github.com/dsully/qbit-tools.git";
      mainProgram = "qbit-status";
      platforms = lib.platforms.linux;
    };
  }
else emptyFile
