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
    version = "0.4.1";

    src = fetchGit {
      url = "git+ssh://git@github.com/dsully/qbit-tools";
      rev = "c3130a73c7438e345a08f775dbbe6fb1d5a82760";
    };

    cargoHash = "sha256-T+rEnXHltZAO4brTPkZ/S45t4mZvsCPd631iXOt9K8U=";
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
