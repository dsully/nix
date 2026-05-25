{
  emptyFile,
  lib,
  rcodesign,
  stdenv,
  swift,
}:
if stdenv.hostPlatform.isDarwin
then
  stdenv.mkDerivation (finalAttrs: {
    pname = "opencode-notifier";
    version = "1.0.0";

    src = ./.;

    nativeBuildInputs = [rcodesign swift];

    dontConfigure = true;

    # rcodesign seals the .app bundle below; stripping afterwards would
    # invalidate that signature. macOS silently refuses to deliver
    # notifications from a bundle whose signature doesn't validate, so the
    # full bundle seal (not just the linker's Mach-O signing) is required.
    dontStrip = true;

    buildPhase =
      # bash
      ''
        runHook preBuild

        swiftc -O -o OpenCodeNotifier main.swift \
          -framework Cocoa -framework UserNotifications

        runHook postBuild
      '';

    installPhase =
      # bash
      ''
        runHook preInstall

        mkdir -p $out/Applications $out/libexec $out/share/opencode/plugins

        # Assemble an .app bundle around the notifier binary, then ad-hoc sign
        # and seal the whole bundle so macOS accepts it for notifications.
        app="$out/Applications/OpenCodeNotifier.app"
        mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
        cp OpenCodeNotifier "$app/Contents/MacOS/OpenCodeNotifier"
        cp Info.plist "$app/Contents/Info.plist"
        cp icon.icns "$app/Contents/Resources/AppIcon.icns"
        rcodesign sign "$app"

        install -m755 detect-ghostty-tab.sh $out/libexec/detect-ghostty-tab.sh
        install -m755 session-tty.sh $out/libexec/session-tty.sh
        install -m755 focus-ghostty-tab.sh $out/libexec/focus-ghostty-tab.sh

        cp notifier.js $out/share/opencode/plugins/notifier.js
        substituteInPlace $out/share/opencode/plugins/notifier.js \
          --replace-fail '@detect@' "$out/libexec/detect-ghostty-tab.sh" \
          --replace-fail '@sessiontty@' "$out/libexec/session-tty.sh" \
          --replace-fail '@focus@' "$out/libexec/focus-ghostty-tab.sh"

        runHook postInstall
      '';

    passthru = {
      plugin = "${finalAttrs.finalPackage}/share/opencode/plugins/notifier.js";
    };

    meta = {
      description = "macOS desktop notifications for OpenCode, with click-to-focus Ghostty tabs";
      homepage = "https://github.com/dsully/opencode-notifier";
      platforms = lib.platforms.darwin;
    };
  })
else emptyFile
