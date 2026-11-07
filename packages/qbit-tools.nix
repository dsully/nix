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
    version = "0.4.2";

    src = fetchGit {
      url = "git+ssh://git@github.com/dsully/qbit-tools";
      rev = "92b29aec250e40826ae1f2b0866215390874c2a0";
    };

    cargoHash = "sha256-/uiDE5T+ODbyemLl4niidLlt4QwMSQ0e0+cA1xkkBmc=";
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
