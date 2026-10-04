{
  programs.fd = {
    enable = true;

    extraOptions = [
      "--follow"
      "--absolute-path"
      "--one-file-system"
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
