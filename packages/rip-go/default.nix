{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:
buildGoModule rec {
  pname = "rip-go";
  rev = "ae27d2d0855e02ce05ff63d9baedd054c4e658e2";
  version = "0.2.2";

  src = fetchFromGitHub {
    inherit rev;
    owner = "roniel-rhack";
    repo = "rip-go";
    hash = "sha256-c0G6hkMLkFBetP75YKrh/c/5USR6Vc4TPSVZJTSXDkU=";
  };

  patches = [./gopsutil-v4.patch];

  proxyVendor = true;
  vendorHash = "sha256-wX4LaaYWyqGMstoio5kjhPUODsCyFndw95/vGLUu1FY=";
  doCheck = false;

  ldflags = ["-s" "-w"];

  meta = {
    description = "Fuzzy find and kill processes from your terminal with real-time updates";
    homepage = "https://github.com/roniel-rhack/rip-go";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
