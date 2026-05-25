import Cocoa
import UserNotifications

// Parsed form of the command-line payload.
//
// Usage:
//   OpenCodeNotifier <title> <subtitle> <message> [--tty <tty>] [--icon <path>]
//                  [--focus-script <path>]
//
// A click on a previously-posted banner relaunches this bundle with no
// payload args, so parsing fails and the caller waits for `didReceive`.
private struct Payload {
    let title: String
    let subtitle: String
    let message: String
    var tty: String?
    var iconPath: String?
    var focusScript: String?

    init?(arguments args: [String]) {
        guard args.count >= 4 else { return nil }

        title = args[1]
        subtitle = args[2]
        message = args[3]

        var i = 4
        while i < args.count {
            switch args[i] {
            case "--tty" where i + 1 < args.count:
                tty = args[i + 1]
                i += 2
            case "--icon" where i + 1 < args.count:
                iconPath = args[i + 1]
                i += 2
            case "--focus-script" where i + 1 < args.count:
                focusScript = args[i + 1]
                i += 2
            default:
                i += 1
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    // When relaunched by a click there are no payload args; this guards against
    // the notification response never being delivered.
    private var fallbackTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        let args = CommandLine.arguments

        guard let payload = Payload(arguments: args) else {
            if args.count > 1 {
                fputs(
                    "Usage: OpenCodeNotifier <title> <subtitle> <message> [--tty <tty>] [--icon <path>]\n",
                    stderr)
                NSApp.terminate(nil)
                return
            }
            fallbackTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { _ in
                NSApp.terminate(nil)
            }
            return
        }

        // Post unconditionally. macOS silently denies `requestAuthorization`
        // for new ad-hoc-signed bundles without prompting; the bundle won't
        // appear in System Settings → Notifications until it first tries to
        // post, so `add()` is what registers us with usernoted.
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
            let content = UNMutableNotificationContent()
            content.title = payload.title
            content.subtitle = payload.subtitle
            content.body = payload.message
            content.sound = .default

            // Stash the originating TTY (and the focus helper) so a click can
            // refocus that terminal. userInfo survives the relaunch a click
            // triggers.
            var info: [String: String] = [:]
            if let tty = payload.tty { info["tty"] = tty }
            if let focusScript = payload.focusScript { info["focusScript"] = focusScript }
            content.userInfo = info

            if let iconPath = payload.iconPath,
                let attachment = Self.makeIconAttachment(from: iconPath)
            {
                content.attachments = [attachment]
            }

            let request = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: content,
                trigger: nil
            )

            center.add(request) { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    NSApp.terminate(nil)
                }
            }
        }
    }

    // UNNotificationAttachment requires a PNG/JPEG/GIF file. `.icns` is not accepted directly;
    // if one is passed, render it to a temp PNG first.
    private static func makeIconAttachment(from path: String) -> UNNotificationAttachment? {
        let expanded = (path as NSString).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }

        let ext = url.pathExtension.lowercased()
        let finalURL: URL

        if ext == "png" || ext == "jpg" || ext == "jpeg" || ext == "gif" {
            finalURL = url
        } else {
            guard let png = renderPNG(from: url) else { return nil }
            finalURL = png
        }

        return try? UNNotificationAttachment(
            identifier: "icon",
            url: finalURL,
            options: [UNNotificationAttachmentOptionsThumbnailHiddenKey: false]
        )
    }

    private static func renderPNG(from source: URL) -> URL? {
        guard let image = NSImage(contentsOf: source) else { return nil }
        let size = NSSize(width: 256, height: 256)
        let target = NSImage(size: size)

        target.lockFocus()

        image.draw(
            in: NSRect(origin: .zero, size: size),
            from: .zero,
            operation: .sourceOver,
            fraction: 1.0)

        target.unlockFocus()

        guard
            let tiff = target.tiffRepresentation,
            let rep = NSBitmapImageRep(data: tiff),
            let png = rep.representation(using: .png, properties: [:])

        else { return nil }

        let tmp = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("ocn-\(UUID().uuidString).png")
        do {
            try png.write(to: tmp)
            return tmp
        } catch {
            return nil
        }
    }

    // Released Ghostty (<= 1.3.1) doesn't expose `tty`/`pid` on terminals in
    // its AppleScript dictionary, so the dictionary-based focus below can't
    // match a session yet. Flip this to true once running a Ghostty that has
    // the `tty` property; until then we fall back to AX tab-index focus.
    private static let useDictionaryFocus = false

    // Only the controlled /dev/ttysNNN form is accepted, so a matched value is
    // safe to interpolate into an AppleScript source or pass to a helper.
    private static func isControlledTTY(_ tty: String) -> Bool {
        tty.range(of: "^/dev/tty[a-z0-9]+$", options: .regularExpression) != nil
    }

    // Ask Ghostty (via its own AppleScript dictionary) to focus the terminal
    // surface whose TTY matches, bringing its window to the front. This
    // re-resolves the live terminal by TTY, so it is correct even if tabs were
    // reordered or closed since the notification fired.
    private static func focusGhosttyTerminal(tty: String) {
        guard isControlledTTY(tty) else { return }

        let source = """
            tell application "Ghostty"
                repeat with t in terminals
                    try
                        if tty of t is "\(tty)" then
                            focus t
                            return
                        end if
                    end try
                end repeat
            end tell
            """

        var error: NSDictionary?
        NSAppleScript(source: source)?.executeAndReturnError(&error)
    }

    // Fallback for released Ghostty: a helper script re-resolves the tab live
    // (OSC title marker → Accessibility) and AX-presses it.
    private static func focusGhosttyTab(tty: String, script: String) {
        guard isControlledTTY(tty) else { return }
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = [script, tty]
        try? task.run()
        task.waitUntilExit()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        fallbackTimer?.invalidate()

        let info = response.notification.request.content.userInfo
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier,
            let tty = info["tty"] as? String
        {
            if Self.useDictionaryFocus {
                Self.focusGhosttyTerminal(tty: tty)
            } else if let script = info["focusScript"] as? String {
                Self.focusGhosttyTab(tty: tty, script: script)
            }
        }

        completionHandler()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            NSApp.terminate(nil)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
