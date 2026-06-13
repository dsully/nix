{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "rom";
  version = "0.2.0-unstable-2026-06-03";

  src = fetchFromGitHub {
    owner = "manic-systems";
    repo = "rom";
    rev = "2cd5dae0068b8aea710ab0e98f056bb2877848b0";
    hash = "sha256-or69VhsASxuKqWh7jHprslRIfNh4x7WeEp3Ip4JnUXI=";

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

  cargoHash = "sha256-FvBdpEgFv/WHrfe0U2oy4k7neCN7iOSmNJhNxWNI1Kc=";
  doCheck = false;

  meta = {
    description = "Pretty build graphs for your pretty Nix builds";
    homepage = "https://github.com/manic-systems/rom";
    license = lib.licenses.eupl12;
    mainProgram = pname;
  };
}
