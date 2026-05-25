{
  emptyFile,
  jq,
  lib,
  rcodesign,
  stdenv,
  swift,
}:
if stdenv.hostPlatform.isDarwin
then
  stdenv.mkDerivation (finalAttrs: {
    pname = "agent-notifier";
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

        swiftc -O -o ClaudeNotifier main.swift \
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
        mkBundle() {
          local app="$out/Applications/$1"
          mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
          cp ClaudeNotifier "$app/Contents/MacOS/ClaudeNotifier"
          cp "$2" "$app/Contents/Info.plist"
          cp "$3" "$app/Contents/Resources/AppIcon.icns"
          rcodesign sign "$app"
        }

        mkBundle ClaudeCodeNotifier.app Info.plist claude-icon.icns
        mkBundle OpenCodeNotifier.app Info-OpenCode.plist opencode-icon.icns

        install -m755 detect-ghostty-tab.sh $out/libexec/detect-ghostty-tab.sh
        install -m755 session-tty.sh $out/libexec/session-tty.sh
        install -m755 focus-ghostty-tab.sh $out/libexec/focus-ghostty-tab.sh

        cp opencode-notifier.js $out/share/opencode/plugins/opencode-notifier.js
        substituteInPlace $out/share/opencode/plugins/opencode-notifier.js \
          --replace-fail '@detect@' "$out/libexec/detect-ghostty-tab.sh" \
          --replace-fail '@sessiontty@' "$out/libexec/session-tty.sh" \
          --replace-fail '@focus@' "$out/libexec/focus-ghostty-tab.sh"

        # Claude Code Notification hook (wired via programs.claude-code.hooks).
        install -m755 notification-desktop.sh $out/libexec/notification-desktop.sh
        substituteInPlace $out/libexec/notification-desktop.sh \
          --replace-fail '@detect@' "$out/libexec/detect-ghostty-tab.sh" \
          --replace-fail '@sessiontty@' "$out/libexec/session-tty.sh" \
          --replace-fail '@focus@' "$out/libexec/focus-ghostty-tab.sh" \
          --replace-fail '@jq@' "${lib.getExe jq}"

        runHook postInstall
      '';

    passthru = {
      opencodePlugin = "${finalAttrs.finalPackage}/share/opencode/plugins/opencode-notifier.js";
      claudeNotificationHook = "${finalAttrs.finalPackage}/libexec/notification-desktop.sh";
    };

    meta = {
      description = "macOS desktop notifications for Claude Code and OpenCode, with click-to-focus Ghostty tabs";
      homepage = "https://github.com/dsully/agent-notifier";
      platforms = lib.platforms.darwin;
    };
  })
else emptyFile
