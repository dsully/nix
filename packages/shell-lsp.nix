{
  lib,
  buildGo127Module,
  fetchFromGitHub,
}:
buildGo127Module rec {
  pname = "shell-lsp";
  version = "0.5.22";

  src = fetchFromGitHub {
    owner = "stubbedev";
    repo = "shell-lsp";
    rev = "fde790f5262939945be47883e1bc2e359c60ace0";
    hash = "sha256-yGfy4mkBQkNZFNdId8NxCXQOe3XE0iFsdjwga2Sdy0k=";
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
