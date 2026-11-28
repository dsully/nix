{
  lib,
  buildGo127Module,
  fetchFromGitHub,
}:
buildGo127Module rec {
  pname = "shell-lsp";
  version = "0.5.27";

  src = fetchFromGitHub {
    owner = "stubbedev";
    repo = "shell-lsp";
    rev = "1c699b2bedf90776fc8146aa169f5eedf7006d7e";
    hash = "sha256-jOr0x2KCZMIP6rGx5ztRGkAnOF+gUpQGDs6MvLgM+s0=";
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
