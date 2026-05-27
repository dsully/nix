import CoreFoundation
import Darwin
import Foundation

// Prints full Modifier Keys preference keys for attached Apple keyboards. The
// activation script writes the same mapping to each key so the visible System
// Settings row and the lower-level HID runtime mapping agree.
let preferenceKeyPrefix = "com.apple.keyboard.modifiermapping."

// The private MachineSettings framework owns the same keyboard preference key
// calculation that System Settings uses for Modifier Keys.
typealias CreateKeyForKeyboard = @convention(c) (UnsafeRawPointer?) -> Unmanaged<CFString>?

// Swift does not import these hidsystem APIs from IOKit, so declare the C
// symbols directly here instead of keeping a separate C shim around.
@_silgen_name("IOHIDEventSystemClientCreateSimpleClient")
func eventSystemClientCreateSimpleClient(_ allocator: CFAllocator?) -> Unmanaged<CFTypeRef>?

@_silgen_name("IOHIDEventSystemClientCopyServices")
func eventSystemClientCopyServices(_ client: CFTypeRef?) -> Unmanaged<CFArray>?

@_silgen_name("IOHIDServiceClientCopyProperty")
func serviceClientCopyProperty(
    _ service: UnsafeRawPointer?,
    _ key: CFString
) -> Unmanaged<CFTypeRef>?

// Keep failures explicit: activation intentionally suppresses stderr, but
// running the helper by hand should show which OS boundary failed.
func fail(_ message: String) -> Never {
    fputs("\(message)\n", stderr)
    exit(1)
}

func dlErrorMessage() -> String {
    guard let error = dlerror() else {
        return "unknown error"
    }

    return String(cString: error)
}

// IOHIDServiceClientCopyProperty follows the Core Foundation copy rule. Taking
// the retained value hands ownership to Swift for the lifetime of the value.
func copyProperty(_ service: UnsafeRawPointer?, _ key: String) -> CFTypeRef? {
    serviceClientCopyProperty(service, key as CFString)?.takeRetainedValue()
}

func stringContains(_ value: CFTypeRef?, _ needle: String) -> Bool {
    guard let value, CFGetTypeID(value) == CFStringGetTypeID() else {
        return false
    }

    return (value as! String).contains(needle)
}

func booleanIsTrue(_ value: CFTypeRef?) -> Bool {
    guard let value, CFGetTypeID(value) == CFBooleanGetTypeID() else {
        return false
    }

    return CFBooleanGetValue((value as! CFBoolean))
}

func numberEquals(_ value: CFTypeRef?, _ expected: Int64) -> Bool {
    guard let value, CFGetTypeID(value) == CFNumberGetTypeID() else {
        return false
    }

    var actual: Int64 = 0
    return CFNumberGetValue((value as! CFNumber), .sInt64Type, &actual) && actual == expected
}

func serviceIsTouchIdMagicKeyboard(_ service: UnsafeRawPointer?) -> Bool {
    let product = copyProperty(service, "Product")
    let vendor = copyProperty(service, "VendorID")

    return stringContains(product, "Magic Keyboard")
        && stringContains(product, "Touch ID")
        && numberEquals(vendor, 1452)
}

// Restrict writes to Apple keyboards so activation does not create Modifier
// Keys preferences for unrelated HID devices. "Keyboard Backlight" is filtered
// out because it is an Apple HID service with Keyboard in its product name but
// is not a typing device.
func serviceIsAppleKeyboard(_ service: UnsafeRawPointer?) -> Bool {
    let product = copyProperty(service, "Product")
    let vendor = copyProperty(service, "VendorID")
    let builtIn = copyProperty(service, "Built-In")

    let isKeyboard =
        stringContains(product, "Keyboard")
        && !stringContains(product, "Backlight")
    let isApple =
        booleanIsTrue(builtIn)
        || numberEquals(vendor, 1452)
        || stringContains(product, "Apple")

    return isKeyboard && isApple
}

// Emit the full preference key so the helper owns the OS-specific naming rules
// and the activation shell only has to write the reported key.
func printKeyboardKey(
    createKeyForKeyboard: CreateKeyForKeyboard,
    service: UnsafeRawPointer?
) -> Bool {
    guard let key = createKeyForKeyboard(service)?.takeRetainedValue() else {
        return false
    }

    print("\(preferenceKeyPrefix)\(key as String)")
    return true
}

let frameworkPath =
    "/System/Library/PrivateFrameworks/MachineSettings.framework/Versions/A/MachineSettings"
let fallbackFrameworkPath =
    "/System/Library/PrivateFrameworks/MachineSettings.framework/MachineSettings"

// MachineSettings may be present only through the dyld shared cache, so try the
// versioned path first and then the framework convenience path.
let framework = dlopen(frameworkPath, RTLD_NOW) ?? dlopen(fallbackFrameworkPath, RTLD_NOW)
guard let framework else {
    fail("dlopen MachineSettings failed: \(dlErrorMessage())")
}
defer {
    dlclose(framework)
}

guard let symbol = dlsym(framework, "createKeyForKeyboard") else {
    fail("dlsym createKeyForKeyboard failed: \(dlErrorMessage())")
}

let createKeyForKeyboard = unsafeBitCast(symbol, to: CreateKeyForKeyboard.self)

// A simple client is enough: this process only snapshots current HID services
// during activation and does not subscribe to device-change events.
guard let client = eventSystemClientCreateSimpleClient(kCFAllocatorDefault)?.takeRetainedValue()
else {
    fail("IOHIDEventSystemClientCreateSimpleClient failed")
}

guard let services = eventSystemClientCopyServices(client)?.takeRetainedValue() else {
    fail("IOHIDEventSystemClientCopyServices failed")
}

var printedAny = false
let serviceCount = CFArrayGetCount(services)

for index in 0..<serviceCount {
    let service = CFArrayGetValueAtIndex(services, index)

    if serviceIsAppleKeyboard(service) {
        printedAny =
            printKeyboardKey(
                createKeyForKeyboard: createKeyForKeyboard,
                service: service
            ) || printedAny
    }

    if serviceIsTouchIdMagicKeyboard(service) {
        // Touch ID Magic Keyboards expose createKeyForKeyboard as vendor-product-0,
        // but the visible Modifier Keys row is stored under this alternate handler;
        // without it, System Settings continues to show Globe for the external keyboard.
        print("\(preferenceKeyPrefix)alt_handler_id-109")
        printedAny = true
    }
}

exit(printedAny ? 0 : 1)
