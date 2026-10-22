{
  lib,
  buildGo127Module,
  fetchFromGitHub,
}:
buildGo127Module rec {
  pname = "shell-lsp";
  version = "0.5.7";

  src = fetchFromGitHub {
    owner = "stubbedev";
    repo = "shell-lsp";
    rev = "bf0d770189fc8f5c90b6e44d7ea7f120780a4930";
    hash = "sha256-s0aF8peMoMNReui5Z1x8aQpOZcE5D0Pf/oTKVGu1bd8=";
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
