import Foundation
import Combine

/// Shared joypad state for libretro retro_input_state_t.
/// Thread-safe bit mask; UI sets bits, core reads them.
final class InputBridge: ObservableObject {
    static let shared = InputBridge()

    /// RETRO_DEVICE_ID_JOYPAD_* bits
    private let lock = NSLock()
    private var bits: UInt32 = 0

    // Standard libretro pad IDs
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
        defer { lock.unlock() }
        if pressed {
            bits |= (1 << id)
        } else {
            bits &= ~(1 << id)
        }
    }

    func isPressed(_ id: UInt32) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return (bits & (1 << id)) != 0
    }

    /// Called from C input_state callback
    nonisolated func state(port: UInt32, device: UInt32, index: UInt32, id: UInt32) -> Int16 {
        // RETRO_DEVICE_JOYPAD = 1
        guard port == 0, device == 1 || device == 0 else { return 0 }
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

    /// Map face label → joypad id
    static func faceId(_ label: String) -> UInt32? {
        switch label.uppercased() {
        case "A": return A
        case "B": return B
        case "X": return X
        case "Y": return Y
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
