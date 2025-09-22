{pkgs, ...}:
with pkgs;
  buildNpmPackage {
    pname = "curlconverter";
    version = "4.12.0";

    src = fetchFromGitHub {
      owner = "curlconverter";
      repo = "curlconverter";
      rev = "e1a0301d4640dd0901ff937ba54157175ec1636a";
      hash = "sha256-5PULy4Le4fp30vJpT9bUrL/VVntE3YS2g5tIbmUJNX0=";
    };

    # Patch package.json to remove tree-sitter-cli and modify prepare script
    postPatch = ''
      ${pkgs.jq}/bin/jq '.devDependencies |= del(."tree-sitter-cli") |
        .scripts.prepare = "npm run compile"' \
        package.json > package.json.tmp
      mv package.json.tmp package.json
    '';

    # Override the npm build command since this package uses "compile" not "build"
    npmBuildScript = "compile";

    npmDepsHash = "sha256-UIbMvw8hkZxtSGInV2+Fjm4DZahrdGtSxi0Unhb5lh8=";
    NODE_OPTIONS = "--openssl-legacy-provider";

    meta = {
      description = "Transpile curl commands into Python, JavaScript and 27 other languages";
      homepage = "https://github.com/curlconverter/curlconverter";
      license = lib.licenses.mit;
      mainProgram = "curlconverter";
      platforms = lib.platforms.all;
    };
  }
