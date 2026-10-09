import Foundation
import CoreGraphics
import UIKit
import Combine

/// Built-in CHIP-8 emulator with hex keypad input.
@MainActor
final class Chip8Core: ObservableObject {
    static let shared = Chip8Core()

    @Published private(set) var isRunning = false
    @Published private(set) var frameID: UInt64 = 0

    private var memory = [UInt8](repeating: 0, count: 4096)
    private var V = [UInt8](repeating: 0, count: 16)
    private var I: UInt16 = 0
    private var pc: UInt16 = 0x200
    private var sp: Int = 0
    private var stack = [UInt16](repeating: 0, count: 16)
    private var delayTimer: UInt8 = 0
    private var soundTimer: UInt8 = 0
    private var display = [UInt8](repeating: 0, count: 64 * 32)
    private var keys = [Bool](repeating: false, count: 16)
    private var timer: Timer?
    private let font: [UInt8] = [
        0xF0,0x90,0x90,0x90,0xF0, 0x20,0x60,0x20,0x20,0x70,
        0xF0,0x10,0xF0,0x80,0xF0, 0xF0,0x10,0xF0,0x10,0xF0,
        0x90,0x90,0xF0,0x10,0x10, 0xF0,0x80,0xF0,0x10,0xF0,
        0xF0,0x80,0xF0,0x90,0xF0, 0xF0,0x10,0x20,0x40,0x40,
        0xF0,0x90,0xF0,0x90,0xF0, 0xF0,0x90,0xF0,0x10,0xF0,
        0xF0,0x90,0xF0,0x90,0x90, 0xE0,0x90,0xE0,0x90,0xE0,
        0xF0,0x80,0x80,0x80,0xF0, 0xE0,0x90,0x90,0x90,0xE0,
        0xF0,0x80,0xF0,0x80,0xF0, 0xF0,0x80,0xF0,0x80,0x80,
    ]

    func loadROM(path: String) -> Bool {
        stop()
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return false }
        memory = [UInt8](repeating: 0, count: 4096)
        for i in 0..<font.count { memory[i] = font[i] }
        let bytes = [UInt8](data)
        guard bytes.count < 4096 - 0x200 else { return false }
        for i in 0..<bytes.count { memory[0x200 + i] = bytes[i] }
        V = [UInt8](repeating: 0, count: 16)
        I = 0; pc = 0x200; sp = 0
        delayTimer = 0; soundTimer = 0
        display = [UInt8](repeating: 0, count: 64 * 32)
        keys = [Bool](repeating: false, count: 16)
        isRunning = true
        startLoop()
        return true
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        display = [UInt8](repeating: 0, count: 64 * 32)
        frameID &+= 1
    }

    func setKey(_ k: Int, pressed: Bool) {
        guard k >= 0, k < 16 else { return }
        keys[k] = pressed
    }

    func clearKeys() {
        keys = [Bool](repeating: false, count: 16)
    }

    func makeCGImage() -> CGImage? {
        var rgba = [UInt8](repeating: 0, count: 64 * 32 * 4)
        for i in 0..<(64 * 32) {
            let on = display[i] != 0
            let o = i * 4
            rgba[o] = on ? 200 : 0
            rgba[o+1] = on ? 220 : 0
            rgba[o+2] = on ? 255 : 0
            rgba[o+3] = 255
        }
        guard let provider = CGDataProvider(data: Data(rgba) as CFData) else { return nil }
        return CGImage(width: 64, height: 32, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: 256,
                       space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }

    private func startLoop() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
    }

    private func tick() {
        guard isRunning else { return }
        for _ in 0..<10 { step() }
        if delayTimer > 0 { delayTimer -= 1 }
        if soundTimer > 0 { soundTimer -= 1 }
        frameID &+= 1
    }

    private func step() {
        let op = (UInt16(memory[Int(pc)]) << 8) | UInt16(memory[Int(pc) + 1])
        pc += 2
        let x = Int((op & 0x0F00) >> 8)
        let y = Int((op & 0x00F0) >> 4)
        let n = Int(op & 0x000F)
        let nn = UInt8(op & 0x00FF)
        let nnn = op & 0x0FFF

        switch op & 0xF000 {
        case 0x0000:
            if op == 0x00E0 { display = [UInt8](repeating: 0, count: 64 * 32) }
            else if op == 0x00EE { sp = max(0, sp - 1); pc = stack[sp] }
        case 0x1000: pc = nnn
        case 0x2000:
            stack[sp] = pc; sp = min(15, sp + 1); pc = nnn
        case 0x3000: if V[x] == nn { pc += 2 }
        case 0x4000: if V[x] != nn { pc += 2 }
        case 0x5000: if V[x] == V[y] { pc += 2 }
        case 0x6000: V[x] = nn
        case 0x7000: V[x] = V[x] &+ nn
        case 0x8000:
            switch n {
            case 0: V[x] = V[y]
            case 1: V[x] |= V[y]
            case 2: V[x] &= V[y]
            case 3: V[x] ^= V[y]
            case 4:
                let s = UInt16(V[x]) + UInt16(V[y])
                V[0xF] = s > 255 ? 1 : 0; V[x] = UInt8(s & 0xFF)
            case 5:
                V[0xF] = V[x] >= V[y] ? 1 : 0; V[x] = V[x] &- V[y]
            case 6:
                V[0xF] = V[x] & 1; V[x] >>= 1
            case 7:
                V[0xF] = V[y] >= V[x] ? 1 : 0; V[x] = V[y] &- V[x]
            case 0xE:
                V[0xF] = (V[x] & 0x80) != 0 ? 1 : 0; V[x] <<= 1
            default: break
            }
        case 0x9000: if V[x] != V[y] { pc += 2 }
        case 0xA000: I = nnn
        case 0xB000: pc = nnn + UInt16(V[0])
        case 0xC000: V[x] = UInt8.random(in: 0...255) & nn
        case 0xD000:
            V[0xF] = 0
            let px = Int(V[x]) % 64
            let py = Int(V[y]) % 32
            for row in 0..<n {
                let sprite = memory[Int(I) + row]
                for col in 0..<8 {
                    if (sprite & (0x80 >> col)) != 0 {
                        let dx = (px + col) % 64
                        let dy = (py + row) % 32
                        let idx = dy * 64 + dx
                        if display[idx] == 1 { V[0xF] = 1 }
                        display[idx] ^= 1
                    }
                }
            }
        case 0xE000:
            if nn == 0x9E { if keys[Int(V[x])] { pc += 2 } }
            else if nn == 0xA1 { if !keys[Int(V[x])] { pc += 2 } }
        case 0xF000:
            switch nn {
            case 0x07: V[x] = delayTimer
            case 0x0A:
                if let k = keys.firstIndex(where: { $0 }) { V[x] = UInt8(k) }
                else { pc -= 2 }
            case 0x15: delayTimer = V[x]
            case 0x18: soundTimer = V[x]
            case 0x1E: I += UInt16(V[x])
            case 0x29: I = UInt16(V[x]) * 5
            case 0x33:
                memory[Int(I)] = V[x] / 100
                memory[Int(I)+1] = (V[x] / 10) % 10
                memory[Int(I)+2] = V[x] % 10
            case 0x55:
                for i in 0...x { memory[Int(I)+i] = V[i] }
            case 0x65:
                for i in 0...x { V[i] = memory[Int(I)+i] }
            default: break
            }
        default: break
        }
    }
}
