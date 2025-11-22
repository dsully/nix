{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "magic-opener";
    rev = "06e1901b906b41c224bcb004784dfd22a884a73d";
    version = "06e1901b";

    src = fetchFromGitHub {
      inherit rev;
      owner = "dsully";
      repo = pname;
      hash = "sha256-E852GPKl/J9JUQ5JvAZu3TKLgJaOj741JlJVJH5EbTo=";
    };

    cargoHash = "sha256-BPxPxgwLVey4UJ8gBHSwrE9lKSsPojYQBKYLluCvqSQ=";

    meta = {
      description = "A tool for opening the right thing in the right place";
      homepage = "https://github.com/dsully/magic-opener";
      license = lib.licenses.mit;
      mainProgram = "open";
    };
  }
