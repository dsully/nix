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
    rev = "dccec79a0ced4c9096eaccd19965ead5772d917a";
    hash = "sha256-Mdkcaw+L61vPSVfpneV86G/6cjtUZwzP9VZCPsMWKWc=";
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
