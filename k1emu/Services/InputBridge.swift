import Foundation

/// Shared joypad bits for libretro retro_input_state_t.
/// Atomic bitmask — safe from UI thread and core C callback.
final class InputBridge {
    static let shared = InputBridge()

    private var bits: UInt32 = 0
    private let lock = NSLock()

    // RETRO_DEVICE_ID_JOYPAD_*
    static let B: UInt32 = 0
    static let Y: UInt32 = 1
    static let SELECT: UInt32 = 2
    static let START: UInt32 = 3
    static let UP: UInt32 = 4
    static let DOWN: UInt32 = 5
    static let LEFT: UInt32 = 6
    static let RIGHT: UInt32 = 7
    static let A: UInt32 = 8
    static let X: UInt32 = 9
    static let L: UInt32 = 10
    static let R: UInt32 = 11
    static let L2: UInt32 = 12
    static let R2: UInt32 = 13

    func set(_ id: UInt32, pressed: Bool) {
        lock.lock()
        if pressed { bits |= (1 << id) } else { bits &= ~(1 << id) }
        lock.unlock()
    }

    /// Called from C input_state — accept JOYPAD (1) and generic (0).
    func state(port: UInt32, device: UInt32, index: UInt32, id: UInt32) -> Int16 {
        guard port == 0, id < 16 else { return 0 }
        // RETRO_DEVICE_JOYPAD = 1, some cores pass 0
        if device != 0 && device != 1 { return 0 }
        lock.lock()
        let v = (bits & (1 << id)) != 0
        lock.unlock()
        return v ? 1 : 0
    }

    func clearAll() {
        lock.lock()
        bits = 0
        lock.unlock()
    }

    static func faceId(_ label: String) -> UInt32? {
        switch label.uppercased() {
        case "A", "CROSS", "×", "XBOXA": return A
        case "B", "CIRCLE", "○", "XBOXB": return B
        case "X", "SQUARE", "□", "XBOXX": return X
        case "Y", "TRIANGLE", "△", "XBOXY": return Y
        // Nintendo-style aliases (common on SNES/N64 overlays)
        case "SNESA": return A
        case "SNESB": return B
        case "SNESX": return X
        case "SNESY": return Y
        default: return nil
        }
    }

    static func shoulderId(_ label: String) -> UInt32? {
        switch label.uppercased() {
        case "LB", "L": return L
        case "RB", "R": return R
        case "LT", "L2": return L2
        case "RT", "R2": return R2
        default: return nil
        }
    }
}
