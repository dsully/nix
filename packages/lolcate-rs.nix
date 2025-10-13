{pkgs, ...}:
with pkgs;
  rustPlatform.buildRustPackage rec {
    pname = "lolcate-rs";
    version = "0.2.4";

    src = fetchFromGitHub {
      owner = "dsully";
      repo = pname;
      rev = "a3c71f15b28b3201a766f11cb406d2db9ea15de4";
      hash = "sha256-78OL/C0lG2pt9BddbOUOmM65V7ty/3qxOw/p8+KCSFI=";
    };

    cargoHash = "sha256-7BnEw8ikkIqCw7pymT0Yx9wKpsTMNLtUkwosfEfQSIE=";

    meta = {
      description = "Lolcate -- A comically fast way of indexing and querying your filesystem. Replaces locate / mlocate / updatedb. Written in Rust";
      homepage = "https://github.com/dsully/lolcate-rs";
      license = lib.licenses.gpl3Only;
      maintainers = ["dsully"];
      mainProgram = "lolcate";
    };
  }
