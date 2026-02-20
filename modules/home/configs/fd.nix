{
  programs.fd = {
    enable = true;

    extraOptions = [
      "--follow"
      "--full-path"
    ];

    hidden = true;

    ignores = [
      ".git/"
      ".venv/"
      "build-results/"
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
