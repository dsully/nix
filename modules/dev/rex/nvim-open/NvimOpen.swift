// NvimOpen                             LaunchServices handler: files and rex-nvim:// URLs -> registered nvim or nvim-open.lua
// NvimOpen open FILE[:LINE[:COL]]...   the same from a shell; inside Rex, only the caller's session ($REX_SESSION)
// NvimOpen plist ID REX NVIM STATE ROUTE EXT...   print Info.plist (rex.nix activation)
// NvimOpen icon BADGE OUT               write the Rex icon with a BADGE png in a dark corner as OUT.icns
// NvimOpen bind|status [EXT...]        set or show the default app per extension (default: Info.plist's)
import AppKit
import UniformTypeIdentifiers
import UserNotifications

// Generic types make macOS offer NvimOpen for every file; public.html makes it the web browser.
let forbidden: Set<String> = [
  "public.data", "public.item", "public.content", "public.text", "public.html", "public.xhtml",
]

func type(_ ext: String) -> UTType { UTType(filenameExtension: ext) ?? .data }

func plist(
  _ id: String, _ rex: String, _ nvim: String, _ state: String, _ route: String, _ exts: [String]
) {
  // LaunchServices refuses a default handler for a dynamic type, so those get an imported one.
  let imported = exts.filter { type($0).isDynamic || type($0).identifier == "\(id).\($0)" }
  let types = exts.map { imported.contains($0) ? "\(id).\($0)" : type($0).identifier }
  let info: [String: Any] = [
    "CFBundleIdentifier": id,
    "CFBundleName": "NvimOpen",
    "CFBundleExecutable": "NvimOpen",
    "CFBundleIconFile": "AppIcon",
    "CFBundlePackageType": "APPL",
    "LSUIElement": true,
    "RexNvimRex": rex,
    "RexNvimNvim": nvim,
    "RexNvimState": state,
    "RexNvimRoute": route,
    "RexNvimExtensions": exts,
    "CFBundleURLTypes": [["CFBundleURLName": "rex-nvim", "CFBundleURLSchemes": ["rex-nvim"]]],
    "CFBundleDocumentTypes": [
      [
        "CFBundleTypeName": "Source",
        "CFBundleTypeRole": "Editor",
        "LSHandlerRank": "Alternate",
        "LSItemContentTypes": Array(Set(types).subtracting(forbidden)),
      ]
    ],
    "UTImportedTypeDeclarations": imported.map {
      [
        "UTTypeIdentifier": "\(id).\($0)",
        "UTTypeConformsTo": ["public.plain-text", "public.source-code"],
        "UTTypeTagSpecification": ["public.filename-extension": [$0]],
      ]
    },
  ]
  FileHandle.standardOutput.write(
    try! PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0))
}

func icon(_ badge: String, _ out: String) {
  guard
    let rex = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.superlogical.rex"),
    let nvim = NSImage(contentsOfFile: badge)
  else {
    FileHandle.standardError.write(
      "NvimOpen: Rex or \(badge) not found, no icon\n".data(using: .utf8)!)
    return
  }
  let base = NSWorkspace.shared.icon(forFile: rex.path)
  let sizes = [16, 32, 64, 128, 256, 512, 1024]
  let dest = CGImageDestinationCreateWithURL(
    URL(fileURLWithPath: out) as CFURL, UTType.icns.identifier as CFString, sizes.count, nil)!
  for s in sizes {
    let rep = NSBitmapImageRep(
      bitmapDataPlanes: nil, pixelsWide: s, pixelsHigh: s, bitsPerSample: 8, samplesPerPixel: 4,
      hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let d = CGFloat(s)
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    base.draw(in: NSRect(x: 0, y: 0, width: d, height: d))
    // Dark lower-right corner inside the macOS icon squircle (100/824/185 on a 1024 grid), cut short of the dino's mouth.
    let u = d / 1024
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(
      roundedRect: NSRect(x: 100 * u, y: 100 * u, width: 824 * u, height: 824 * u),
      xRadius: 185 * u, yRadius: 185 * u
    ).addClip()
    let corner = NSBezierPath()
    corner.move(to: NSPoint(x: 260 * u, y: 0))
    corner.line(to: NSPoint(x: d, y: 0))
    corner.line(to: NSPoint(x: d, y: d - 260 * u))
    corner.close()
    corner.addClip()
    NSColor(srgbRed: 0x2E / 255, green: 0x34 / 255, blue: 0x40 / 255, alpha: 1).setFill()
    NSRect(x: 0, y: 0, width: d, height: d).fill()
    NSGraphicsContext.restoreGraphicsState()
    nvim.draw(in: NSRect(x: 640 * u, y: 120 * u, width: 260 * u, height: 260 * u))
    NSGraphicsContext.restoreGraphicsState()
    CGImageDestinationAddImage(dest, rep.cgImage!, nil)
  }
  if !CGImageDestinationFinalize(dest) {
    FileHandle.standardError.write("NvimOpen: writing \(out) failed\n".data(using: .utf8)!)
  }
}

func app(_ t: UTType) -> String {
  NSWorkspace.shared.urlForApplication(toOpen: t)?.deletingPathExtension().lastPathComponent ?? "-"
}

// macOS asks the user to confirm each change, so this waits for the answer.
func bind(_ exts: [String]) {
  for t in Set(exts.map(type)) where app(t) != "NvimOpen" && !forbidden.contains(t.identifier) {
    var done = false
    NSWorkspace.shared.setDefaultApplication(at: Bundle.main.bundleURL, toOpen: t) { err in
      print(t.identifier, err.map { "not bound: \($0.localizedDescription)" } ?? "bound")
      done = true
    }
    while !done { RunLoop.main.run(until: Date() + 0.1) }
  }
}

func notify(_ msg: String) {
  NSLog("%@", msg)
  let center = UNUserNotificationCenter.current()
  let content = UNMutableNotificationContent()
  content.title = "rex-nvim"
  content.body = msg
  var done = false
  center.requestAuthorization(options: [.alert]) { granted, _ in
    guard granted else {
      done = true
      return
    }
    center.add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    { _ in done = true }
  }
  while !done { RunLoop.main.run(until: Date() + 0.1) }
}

func physical(_ path: String) -> String {
  guard let p = realpath(path, nil) else { return path }
  defer { free(p) }
  return String(cString: p)
}

typealias File = (path: String, line: Int, col: Int)

// A file URL or rex-nvim://open/PATH?line=N&column=M.
func target(_ url: URL) -> File {
  if url.isFileURL { return (physical(url.path), 0, 0) }
  let c = URLComponents(url: url, resolvingAgainstBaseURL: false)
  let q = { (n: String) in Int(c?.queryItems?.first { $0.name == n }?.value ?? "") ?? 0 }
  return (physical(c?.path ?? ""), q("line"), max(q("column"), q("col")))
}

// FILE[:LINE[:COL]]; a name that exists is never split, so a file named "a:1" opens.
func target(_ arg: String) -> File {
  var parts = arg.split(separator: ":", omittingEmptySubsequences: false).map(String.init)
  var nums: [Int] = []
  if !FileManager.default.fileExists(atPath: arg) {
    while nums.count < 2, parts.count > 1, parts.last!.allSatisfy({ $0.isASCII && $0.isNumber }),
      let n = Int(parts.last!)
    {
      nums.insert(n, at: 0)
      parts.removeLast()
    }
  }
  let path = URL(fileURLWithPath: parts.joined(separator: ":")).standardizedFileURL.path
  return (physical(path), nums.first ?? 0, nums.count > 1 ? nums[1] : 0)
}

// Written by nvim's rex-nvim.registry, one <pid>.json per nvim in a Rex pane.
struct Registration: Decodable {
  let root: String, session: String, block: String, server: String, time: Double
  var file = ""
  enum CodingKeys: String, CodingKey { case root, session, block, server, time }
}

// Deepest root first, then the most recently used.
func registrations(_ dir: String) -> [Registration] {
  let names = (try? FileManager.default.contentsOfDirectory(atPath: dir)) ?? []
  return names.filter { $0.range(of: #"^\d+\.json$"#, options: .regularExpression) != nil }
    .compactMap { name -> Registration? in
      let file = dir + "/" + name
      guard let data = FileManager.default.contents(atPath: file),
        var reg = try? JSONDecoder().decode(Registration.self, from: data)
      else { return nil }
      reg.file = file
      return reg
    }.sorted { ($0.root.count, $0.time) > ($1.root.count, $1.time) }
}

enum Sent {
  case ok, gone
  case failed(String)
}

func name(_ path: String) -> String { (path as NSString).lastPathComponent }

// Not --remote: rex-nvim.open picks a usable window and skips the swap-file prompt.
func send(_ nvim: String, _ reg: Registration, _ f: File) -> Sent {
  let p = Process()
  let out = Pipe()
  let exited = DispatchSemaphore(value: 0)
  p.executableURL = URL(fileURLWithPath: nvim)
  p.arguments = [
    "--server", reg.server, "--remote-expr",
    "luaeval('require(\"rex-nvim\").open(_A[1], _A[2], _A[3])', ['\(f.path.replacingOccurrences(of: "'", with: "''"))', \(f.line), \(f.col)])",
  ]
  p.standardOutput = out
  p.standardError = FileHandle.nullDevice
  p.terminationHandler = { _ in exited.signal() }
  do { try p.run() } catch { return .failed("cannot run \(nvim): \(error.localizedDescription)") }
  if exited.wait(timeout: .now() + 3) == .timedOut {
    p.terminate()
    return .failed("nvim in \(name(reg.root)) is busy; \(name(f.path)) opens elsewhere")
  }
  if p.terminationStatus != 0 { return .gone }
  let reply = String(decoding: out.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
  return reply.hasPrefix("ok")
    ? .ok : .failed("nvim in \(name(reg.root)) could not open \(name(f.path)): \(reply)")
}

// Sends each file to a registered nvim whose root holds it (in session's, when given), and hands the rest,
// plus the panes to focus, to nvim-open.lua. Returns the messages for the user and whether nvim-open.lua failed.
func route(_ files: [File], session: String?) -> (messages: [String], failed: Bool) {
  let info = Bundle.main.infoDictionary!
  let nvim = info["RexNvimNvim"] as! String
  var regs = registrations(info["RexNvimState"] as! String)
  var messages: [String] = []
  var left: [[Any]] = []
  var focus: [[String]] = []

  for f in files {
    var sent = false
    for reg in regs
    where !sent && under(reg.root, f.path) && (session == nil || reg.session == session) {
      switch send(nvim, reg, f) {
      case .ok:
        focus.append([reg.session, reg.block])
        sent = true
      case .gone:
        try? FileManager.default.removeItem(atPath: reg.file)
        regs.removeAll { $0.file == reg.file }
      case .failed(let msg):
        messages.append(msg)
      }
    }
    if !sent { left.append([f.path, f.line, f.col]) }
  }

  var args: [String: Any] = ["nvim": nvim, "focus": focus, "files": left]
  args["session"] = session
  let p = Process()
  let err = Pipe()
  p.executableURL = URL(fileURLWithPath: info["RexNvimRex"] as! String)
  p.arguments = [
    "do", info["RexNvimRoute"] as! String, "--args",
    String(decoding: try! JSONSerialization.data(withJSONObject: args), as: UTF8.self),
  ]
  p.standardError = err
  p.standardOutput = FileHandle.nullDevice
  do { try p.run() } catch {
    return (messages + ["cannot run rex: \(error.localizedDescription)"], true)
  }
  let lua = String(decoding: err.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
  p.waitUntilExit()
  messages += lua.split(separator: "\n").map { $0.replacingOccurrences(of: "rex-nvim: ", with: "") }
  return (messages, p.terminationStatus != 0)
}

func under(_ dir: String, _ path: String) -> Bool { path.hasPrefix(dir + "/") }

func showRex(activate: Bool) {
  let cfg = NSWorkspace.OpenConfiguration()
  cfg.activates = activate
  NSWorkspace.shared.openApplication(
    at: NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.superlogical.rex")!,
    configuration: cfg)
}

final class Handler: NSObject, NSApplicationDelegate {
  func application(_: NSApplication, open urls: [URL]) {
    showRex(activate: false)  // nvim-open.lua waits for the app before switching its session.
    let result = route(urls.map(target), session: nil)
    if !result.messages.isEmpty { notify(result.messages.joined(separator: "\n")) }
    showRex(activate: true)
    NSApp.terminate(nil)
  }

  // Launched without files (double-clicked): nothing to do.
  func applicationDidFinishLaunching(_: Notification) {
    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { NSApp.terminate(nil) }
  }
}

func extensions(_ argv: [String]) -> [String] {
  argv.count > 1
    ? Array(argv.dropFirst()) : Bundle.main.infoDictionary!["RexNvimExtensions"] as! [String]
}

let argv = Array(CommandLine.arguments.dropFirst())
switch argv.first {
case "plist": plist(argv[1], argv[2], argv[3], argv[4], argv[5], Array(argv.dropFirst(6)))
case "icon": icon(argv[1], argv[2])
case "bind": bind(extensions(argv))
case "open":
  let session = ProcessInfo.processInfo.environment["REX_SESSION"].flatMap { $0.isEmpty ? nil : $0 }
  let result = route(argv.dropFirst().map(target), session: session)
  for msg in result.messages {
    FileHandle.standardError.write("rex-nvim: \(msg)\n".data(using: .utf8)!)
  }
  exit(result.failed ? 1 : 0)
case "status": for ext in extensions(argv) { print(ext, type(ext).identifier, app(type(ext))) }
case nil:
  let handler = Handler()
  NSApplication.shared.delegate = handler
  NSApplication.shared.run()
default:
  FileHandle.standardError.write(
    "usage: rex-nvim open FILE[:LINE[:COL]]... | bind | status\n".data(using: .utf8)!)
  exit(64)
}
