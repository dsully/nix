{
  lib,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  rev = "acff259b15cac4592a0f24b175d1057c34b2cbce";
  pname = "geil";
  version = "0.0.1-alpha.1-${rev}";

  src = fetchFromGitHub {
    inherit rev;
    owner = "Nukesor";
    repo = pname;
    hash = "sha256-A8XVIZ8ZufYoPJPYAzeqqsTG6xTcYDdZSAwq3c/m31E=";
  };

  cargoHash = "sha256-/Ei+Mfyla5tKuAWhDgyoEZOPHp1tN5ry3GlZLHh0aVE=";
  doCheck = false;

  # dirs::state_dir() is None on macOS; use XDG_STATE_HOME, then ~/.local/state.
  postPatch = ''
    substituteInPlace src/state.rs --replace-fail \
      'dirs::state_dir().ok_or_else(|| anyhow!("Couldn'"'"'t resolve home dir"))?' \
      'std::env::var_os("XDG_STATE_HOME").map(PathBuf::from).or_else(dirs::state_dir).or_else(|| dirs::home_dir().map(|h| h.join(".local/state"))).ok_or_else(|| anyhow!("Couldn'"'"'t resolve state dir"))?'
  '';

  meta = {
    description = "Rocket: A tool to update your repositories and for keeping them clean";
    homepage = "https://github.com/Nukesor/geil";
    license = lib.licenses.mit;
    mainProgram = pname;
  };
}
