# NvimOpen.app: the macOS handler that opens clicked files and rex-nvim:// URLs in nvim inside Rex.
{
  config,
  lib,
  my,
  pkgs,
  rexCli,
}: let
  homeDir = config.home.homeDirectory;
  app = "${homeDir}/Applications/NvimOpen.app";
  bundleId = "org.sully.NvimOpen";
  nvim = lib.getExe my.pkgs.neovim;
  state = "${config.xdg.cacheHome}/rex-nvim";

  # nvim's side: registers each nvim in a Rex pane and opens what NvimOpen sends it. On the default runtimepath via the profile.
  site = pkgs.runCommand "rex-nvim-site" {} ''
    mkdir -p $out/share/nvim
    cp -r ${./nvim} $out/share/nvim/site
    chmod -R u+w $out
    substituteInPlace $out/share/nvim/site/lua/rex-nvim/registry.lua --replace-fail @state@ ${state}
  '';

  # Extensions NvimOpen opens. ts is typed as MPEG-2 video first, so .ts videos open in nvim too.
  # Never add html/htm: that makes NvimOpen the default web browser.
  types = lib.splitString " " "c cc conf cpp css fish go gradle h hpp java js json jsx kt kts lock lua m md mjs mm nix properties py rb rs scss sh sql swift toml ts tsx txt xml yaml yml zsh";

  # shortcut: impure /usr/bin/swiftc (Xcode CLT) works because the Nix sandbox is off on darwin.
  # nixbld cannot read the user's xcode-select target, so this is the CLT swiftc; its default SDK may be built by a newer Swift than the CLT ships, so fall back through installed SDKs newest-first.
  bin = pkgs.stdenvNoCC.mkDerivation {
    name = "nvim-open";
    src = ./NvimOpen.swift;
    dontUnpack = true;
    buildPhase = ''
      for sdk in "" $(printf '%s\n' /Library/Developer/CommandLineTools/SDKs/MacOSX*.sdk | sort -rV); do
        echo "trying SDK: ''${sdk:-default}"
        env -i PATH=/usr/bin:/bin HOME="$TMPDIR" /usr/bin/swiftc -O -swift-version 5 \
          ''${sdk:+-sdk "$sdk"} -module-cache-path "$TMPDIR/mc" "$src" -o NvimOpen && break
      done
      [ -x NvimOpen ]
    '';
    installPhase = "install -Dm755 NvimOpen $out/bin/NvimOpen";
    meta.mainProgram = "NvimOpen";
  };
in {
  packages = [
    site
    (pkgs.writeShellScriptBin "rex-nvim" ''exec "${app}/Contents/MacOS/NvimOpen" "$@"'')
  ];

  # Info.plist asks LaunchServices which types need importing, so it is written here, not at build time.
  # Rebuilt only when its inputs change: each rebuild re-registers the app.
  activation = ''
    app="${app}"
    want="${bin} ${rexCli} ${nvim} ${state} ${./nvim-open.lua} ${./AppIcon.icns} ${lib.concatStringsSep " " types}"

    if [ "$(cat "$app/Contents/Resources/nix-inputs" 2>/dev/null)" != "$want" ]; then
      tmp=$(mktemp -d)
      new="$tmp/NvimOpen.app"
      mkdir -p "$new/Contents/MacOS" "$new/Contents/Resources"
      install -m755 ${lib.getExe bin} "$new/Contents/MacOS/NvimOpen"

      "$new/Contents/MacOS/NvimOpen" plist ${bundleId} ${lib.getExe rexCli} ${nvim} ${state} ${./nvim-open.lua} \
        ${lib.escapeShellArgs types} >"$new/Contents/Info.plist"
      # Regenerate with: NvimOpen icon <neovim-unwrapped>/share/icons/hicolor/128x128/apps/nvim.png AppIcon.icns
      install -m644 ${./AppIcon.icns} "$new/Contents/Resources/AppIcon.icns"

      printf '%s' "$want" >"$new/Contents/Resources/nix-inputs"

      /usr/bin/codesign --force --sign - "$new"

      # Swapped in only when complete: bound types must never point at a missing app.
      run mkdir -p "${homeDir}/Applications"
      run rm -rf "$app"
      run mv "$new" "$app"
      run /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$app"
      rm -rf "$tmp"
    fi
  '';
}
