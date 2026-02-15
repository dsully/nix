{
  programs.fd = {
    enable = true;

    ignores = [
      ".git/"
      ".venv/"
      "Cargo.lock"
      "flake.lock"
      "package-lock.json"
      "target/"
      "uv.lock"
      "vendor/"
      "yarn.lock"
    ];
  };
}
