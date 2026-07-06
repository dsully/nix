{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rom";
  rev = "bdf5edf384cfbe7651b71f83324eadb9301abf62";
  version = "0.2.0-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "manic-systems";
    repo = "rom";
    hash = "sha256-7gCPo5Zl/KrGlj3+5/Ed6wUmmgKD93HgPHv1vWqf3WQ=";

    # A test fixture embeds the literal store path of nixpkgs' fetch-builder
    # `source-stdenv.sh`, which is also an inputSrc of this very FOD. Nix's
    # reference scanner therefore rejects the fetched source. Neutralize the
    # colliding path; the fixture is test-only and doCheck is disabled.
    postFetch = ''
      substituteInPlace $out/crates/cognos/src/aterm.rs \
        --replace-fail \
        '/nix/store/l622p70vy8k5sh7y5wizi5f2mic6ynpg-source-stdenv.sh' \
        '/redacted/source-stdenv.sh'
    '';
  };

  cargoHash = "sha256-kB8qDrmhaaR3DSgGGaLfYDE4PP1fsq0w7FuIHncttMI=";
  doCheck = false;

  meta = {
    description = "Pretty build graphs for your pretty Nix builds";
    homepage = "https://github.com/manic-systems/rom";
    license = lib.licenses.eupl12;
    mainProgram = pname;
  };
}
