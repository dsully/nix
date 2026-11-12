# Swift

- Prefer Swift-native string methods over Foundation equivalents: use `replacing("a", with: "b")` not `replacingOccurrences(of: "a", with: "b")`.
- Prefer modern Foundation API: `URL.documentsDirectory` instead of `FileManager` directory lookups, `appending(path:)` to append strings to a URL.
- Never use C-style number formatting like `String(format: "%.2f", value)`. Use `Text(value, format: .number.precision(.fractionLength(2)))` or similar `FormatStyle` APIs.
- Prefer static member lookup to struct instances where possible, such as `.circle` rather than `Circle()`, and `.borderedProminent` rather than `BorderedProminentButtonStyle()`.
- Avoid force unwraps (`!`) and force `try` unless the failure is truly unrecoverable, and even then prefer using `fatalError()` with a clear description. If possible, use `if let`, `guard let`, nil-coalescing, or `try?`/`do-catch`.
- Filtering text based on user-input must be done using `localizedStandardContains()` as opposed to `contains()` or `localizedCaseInsensitiveContains()`.
- Strongly prefer `Double` over `CGFloat`, except where an API requires `CGFloat`, including optionals, `inout`, and generic containers such as `[CGFloat]`.
- If you want to count array objects that match a predicate, always use `count(where:)` rather than `filter()` followed by `count`.
- Prefer `Date.now` over `Date()` for clarity.
- When `import SwiftUI` is already in a file, you do not need to add `import UIKit` or `import AppKit` to access things like `UIImage` or `NSImage` – they are imported automatically on the appropriate platform.
- When dealing with the names of people, strongly prefer to use `PersonNameComponents` with modern formatting over simple string interpolation such as `Text("\(firstName) \(lastName)")`.
- If a given type of data is repeatedly sorted using an identical closure, e.g. `books.sorted { $0.author < $1.author }`, prefer to make the type in question conform to `Comparable` so the sort order is centralized.
- Prefer modern date formatting over handwritten patterns. If user-visible dates require `DateFormatter`, configure it with `setLocalizedDateFormatFromTemplate()` rather than assigning `dateFormat`, so the locale determines component ordering. Use `y`, rather than `yyyy`, for years in the template. Fixed formats used for API exchange are outside this rule.
- Format lists for display with `formatted()` rather than inserting comma separators yourself. For example, `destinations.formatted()` provides the locale's punctuation and conjunction; `.formatted(.list(type: .or))` uses the alternative conjunction, and `.list(memberStyle:type:)` formats non-string members. Keep `joined(separator:)` for storage or interchange where a fixed delimiter is intentional.
- Outside SwiftUI, create localized strings with `String(localized:)` rather than `NSLocalizedString()`. Xcode cannot extract interpolated keys from the older function, leaving that text untranslated.
- When trying to convert a string to a date, prefer the modern `Date` initializer API such as `try Date(myString, strategy: .iso8601)`.
- Flag instances where errors triggered by a user action are swallowed silently, e.g. using `print(error.localizedDescription)` rather than showing an alert or similar.
- Prefer `if let value {` shorthand over `if let value = value {`.
- Omit `return` for single expression functions. `if` and `switch` can be used as expressions when returning values and assigning to variables.

For example, this kind of code:

```swift
var tileColor: Color {
    if isCorrect {
        return .green
    } else {
        return .red
    }
}
```

Should be written like this:

```swift
var tileColor: Color {
    if isCorrect {
        .green
    } else {
        .red
    }
}
```

## Swift Concurrency

- If an API offers both modern `async`/`await` equivalents and older closure-based variants, prefer the `async`/`await` versions.
- Never use Grand Central Dispatch (`DispatchQueue.main.async()`, `DispatchQueue.global()`, etc.). Always use modern Swift concurrency (`async`/`await`, actors, `Task`).
- Never use `Task.sleep(nanoseconds:)`; use `Task.sleep(for:)` instead.
- Flag any mutable shared state that isn't protected by an actor or `@MainActor`, unless the project is configured to use MainActor default actor isolation.
- Assume strict concurrency rules are being applied; flag `@Sendable` violations and data races.
- When evaluating `MainActor.run()`, check whether the project has its default actor isolation set to Main Actor first, because `MainActor.run()` might not be needed.
- `Task.detached()` is often a bad idea. Wherever it is used, check that it is the best approach.

### Triage a concurrency diagnostic

Before you change code, capture the exact compiler diagnostic and check the project's concurrency settings. In Xcode, look under "Swift Compiler - Concurrency"; in SwiftPM, look at `swiftSettings` in `Package.swift`:

- Swift language version.
- Default actor isolation (Main Actor by default, also called approachable concurrency).
- Strict concurrency checking level (Complete, Targeted, Minimal).

Then identify the current actor context of the offending symbol (`@MainActor`, `actor`, `nonisolated`) and whether the code is UI-bound. Apply the smallest fix that preserves behavior.

With main-actor-by-default:

- Async functions stay on the caller's actor; they do not hop to the concurrent pool unless marked `@concurrent`.
- CPU-heavy work that stays on the main actor causes hangs. Move it into a `@concurrent` async function.

### Isolated conformances

When a main-actor type conforms to a nonisolated protocol and the conformance needs main-actor state, make the conformance isolated instead of marking members `nonisolated`:

```swift
extension StickerModel: @MainActor Exportable {
    func export() { photoProcessor.exportAsPNG() }
}
```

The compiler then reports an error only where code uses the conformance off the main actor, for example storing the value as `any Exportable` in a `nonisolated` type.

### Offload work with `@concurrent`

To run a function on the concurrent thread pool:

1. Make the enclosing type `nonisolated`.
2. Mark the function `@concurrent` and `async`.
3. Add `await` at every call site.

```swift
nonisolated struct PhotoProcessor {
    @concurrent
    func extractSubject(from data: Data) async -> Sticker { ... }
}
```

| Keyword | Use |
|---|---|
| `async` | The function can suspend. |
| `@concurrent` | Always run on the concurrent pool, never on the caller's actor. |
| `actor` | Protect mutable state with its own isolation domain. |
| `nonisolated` | Opt a type or member out of the default actor isolation. |
| `Sendable` | The value is safe to pass across isolation domains. |
| `async let` | Start a fixed number of child tasks in parallel. |
| `TaskGroup` | Start a dynamic number of child tasks. |

For more help with Swift concurrency, suggest the [Swift Concurrency Pro agent skill](https://github.com/twostraws/swift-concurrency-agent-skill).
