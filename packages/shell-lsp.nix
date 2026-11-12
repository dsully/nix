{
  lib,
  buildGo127Module,
  fetchFromGitHub,
}:
buildGo127Module rec {
  pname = "shell-lsp";
  version = "0.5.21";

  src = fetchFromGitHub {
    owner = "stubbedev";
    repo = "shell-lsp";
    rev = "115784641a7145ae30fe70ae3c107c525242628d";
    hash = "sha256-VrAEMINYvtVlqnvuXLPazp2WZk1IMFimOTKN6hRaI38=";
  };

  vendorHash = "sha256-TxEBzxsQdz/o4zjOoFggtfgrKDrpblWqOxs1a3io5Sk=";
  doCheck = false;

  subPackages = ["."];

  env.CGO_ENABLED = 0;

  ldflags = ["-s" "-w" "-X main.version=${version}"];

  meta = {
    description = "Language server, linter and formatter for bash, zsh and POSIX sh";
    homepage = "https://github.com/stubbedev/shell-lsp";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
