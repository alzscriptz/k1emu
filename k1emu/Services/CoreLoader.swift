import Foundation
import Darwin

/// Libretro host: dlopen cores, set video callback, run frames into FrameBuffer.
@MainActor
final class CoreLoader: ObservableObject {
    static let shared = CoreLoader()

    @Published private(set) var loadedCoreName: String?
    @Published private(set) var lastError: String?
    @Published private(set) var isLibretro: Bool = false
    @Published private(set) var coreVersion: String?
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var triedPaths: [String] = []

    private var handle: UnsafeMutableRawPointer?
    private var sym_init: UnsafeMutableRawPointer?
    private var sym_deinit: UnsafeMutableRawPointer?
    private var sym_api_version: UnsafeMutableRawPointer?
    private var sym_load_game: UnsafeMutableRawPointer?
    private var sym_unload_game: UnsafeMutableRawPointer?
    private var sym_run: UnsafeMutableRawPointer?
    private var sym_reset: UnsafeMutableRawPointer?
    private var sym_set_video: UnsafeMutableRawPointer?
    private var sym_set_input_poll: UnsafeMutableRawPointer?
    private var sym_set_input_state: UnsafeMutableRawPointer?
    private var sym_set_audio: UnsafeMutableRawPointer?
    private var sym_set_audio_batch: UnsafeMutableRawPointer?
    private var sym_set_env: UnsafeMutableRawPointer?
    private var runTimer: Timer?

    private let coreNames: [String: [String]] = [
        "NDS": ["melondsds_libretro", "libnds", "melonds", "melondsds", "nds_libretro", "desmume"],
        "GBA": ["mgba_libretro", "gba_libretro", "mgba"],
        "GB":  ["gambatte_libretro", "sameboy_libretro", "gb_libretro"],
        "GBC": ["gambatte_libretro", "sameboy_libretro", "gbc_libretro"],
        "NES": ["fceumm_libretro", "nestopia_libretro", "nes_libretro"],
        "SNES": ["snes9x_libretro", "snes_libretro"],
        "CHIP8": []
    ]

    private var documentsCores: URL {
        let u = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Cores", isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    func prepareBundledCores() {
        let fm = FileManager.default
        var sources: [URL] = []
        if let exe = Bundle.main.executableURL?.deletingLastPathComponent() {
            sources.append(exe.appendingPathComponent("Frameworks")); sources.append(exe)
        }
        if let res = Bundle.main.resourceURL {
            sources.append(res.appendingPathComponent("Frameworks"))
            sources.append(res.appendingPathComponent("Cores"))
        }
        if let pf = Bundle.main.privateFrameworksURL { sources.append(pf) }

        for dir in sources {
            guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { continue }
            for f in files where f.pathExtension == "dylib" {
                let dest = documentsCores.appendingPathComponent(f.lastPathComponent)
                if fm.fileExists(atPath: dest.path) {
                    let a = (try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                    let b = (try? dest.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                    if a == b { continue }
                    try? fm.removeItem(at: dest)
                }
                try? fm.copyItem(at: f, to: dest)
            }
        }
    }

    func listAvailableCores() -> [String] {
        prepareBundledCores()
        var names: [String] = []
        for dir in searchDirs {
            guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { continue }
            for f in files where f.pathExtension == "dylib" {
                names.append(f.lastPathComponent)
            }
        }
        return Array(Set(names)).sorted()
    }

    private var searchDirs: [URL] {
        var dirs = [documentsCores]
        if let exe = Bundle.main.executableURL?.deletingLastPathComponent() {
            dirs.append(exe.appendingPathComponent("Frameworks")); dirs.append(exe)
        }
        if let res = Bundle.main.resourceURL {
            dirs.append(res.appendingPathComponent("Frameworks"))
            dirs.append(res.appendingPathComponent("Cores"))
        }
        if let pf = Bundle.main.privateFrameworksURL { dirs.append(pf) }
        return dirs
    }

    static func detectSystem(fileName: String) -> String {
        let ext = (fileName as NSString).pathExtension.lowercased()
        switch ext {
        case "nds", "dsi", "ids": return "NDS"
        case "gba": return "GBA"
        case "gb": return "GB"
        case "gbc": return "GBC"
        case "nes", "fds": return "NES"
        case "sfc", "smc": return "SNES"
        case "ch8", "c8": return "CHIP8"
        case "n64", "z64", "v64": return "N64"
        case "md", "gen", "smd": return "Genesis"
        case "zip": return "NDS"
        default: return "Other"
        }
    }

    @discardableResult
    func loadCore(for system: String) -> Bool {
        unload()
        lastError = nil
        isLibretro = false
        coreVersion = nil
        triedPaths = []
        prepareBundledCores()

        let key = system.uppercased()
        var candidates = coreNames[key] ?? []
        if key == "NDS" {
            candidates = ["melondsds_libretro", "libnds", "melonds", "melondsds", "nds_libretro"]
        }

        var lastDlError = ""
        for dir in searchDirs {
            for base in candidates {
                let url = dir.appendingPathComponent("\(base).dylib")
                triedPaths.append(url.path)
                if FileManager.default.fileExists(atPath: url.path) {
                    if open(path: url.path, name: base) { return true }
                    lastDlError = lastError ?? ""
                }
            }
            if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for f in files where f.pathExtension == "dylib" {
                    let lower = f.lastPathComponent.lowercased()
                    let match = (key == "NDS" && (lower.contains("melon") || lower.contains("nds")))
                        || lower.contains(key.lowercased())
                    if match {
                        triedPaths.append(f.path)
                        if open(path: f.path, name: displayName(f.lastPathComponent)) { return true }
                        lastDlError = lastError ?? ""
                    }
                }
            }
        }

        let found = triedPaths.filter { FileManager.default.fileExists(atPath: $0) }
        lastError = found.isEmpty ? "No dylib for \(system)" : "dlopen failed: \(lastDlError)"
        return false
    }

    private func open(path: String, name: String) -> Bool {
        _ = dlerror()
        var h = dlopen(path, RTLD_LAZY | RTLD_LOCAL)
        if h == nil {
            let e1 = dlerror().map { String(cString: $0) } ?? ""
            _ = dlerror()
            h = dlopen(path, RTLD_NOW | RTLD_LOCAL)
            if h == nil {
                lastError = dlerror().map { String(cString: $0) } ?? e1
                return false
            }
        }

        handle = h
        loadedCoreName = name

        sym_api_version = dlsym(h, "retro_api_version")
        sym_init = dlsym(h, "retro_init")
        sym_deinit = dlsym(h, "retro_deinit")
        sym_load_game = dlsym(h, "retro_load_game")
        sym_unload_game = dlsym(h, "retro_unload_game")
        sym_run = dlsym(h, "retro_run")
        sym_reset = dlsym(h, "retro_reset")
        sym_set_video = dlsym(h, "retro_set_video_refresh")
        sym_set_input_poll = dlsym(h, "retro_set_input_poll")
        sym_set_input_state = dlsym(h, "retro_set_input_state")
        sym_set_audio = dlsym(h, "retro_set_audio_sample")
        sym_set_audio_batch = dlsym(h, "retro_set_audio_sample_batch")
        sym_set_env = dlsym(h, "retro_set_environment")

        guard sym_api_version != nil, sym_init != nil else {
            lastError = "Not a libretro core"
            dlclose(h); handle = nil
            return false
        }

        isLibretro = true

        if let envSym = sym_set_env {
            typealias EnvFn = @convention(c) (@escaping @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Bool) -> Void
            unsafeBitCast(envSym, to: EnvFn.self)(coreEnvironment)
        }
        if let vSym = sym_set_video {
            typealias SetVideo = @convention(c) (@escaping @convention(c) (UnsafeRawPointer?, UInt32, UInt32, Int) -> Void) -> Void
            unsafeBitCast(vSym, to: SetVideo.self)(coreVideoRefresh)
        }
        if let pSym = sym_set_input_poll {
            typealias SetPoll = @convention(c) (@escaping @convention(c) () -> Void) -> Void
            unsafeBitCast(pSym, to: SetPoll.self)(coreInputPoll)
        }
        if let sSym = sym_set_input_state {
            typealias SetState = @convention(c) (@escaping @convention(c) (UInt32, UInt32, UInt32, UInt32) -> Int16) -> Void
            unsafeBitCast(sSym, to: SetState.self)(coreInputState)
        }
        if let aSym = sym_set_audio {
            typealias SetAudio = @convention(c) (@escaping @convention(c) (Int16, Int16) -> Void) -> Void
            unsafeBitCast(aSym, to: SetAudio.self)(coreAudioSample)
        }
        if let bSym = sym_set_audio_batch {
            typealias SetBatch = @convention(c) (@escaping @convention(c) (UnsafePointer<Int16>?, Int) -> Int) -> Void
            unsafeBitCast(bSym, to: SetBatch.self)(coreAudioBatch)
        }

        typealias ApiVersionFn = @convention(c) () -> Int32
        coreVersion = "libretro API \(unsafeBitCast(sym_api_version!, to: ApiVersionFn.self)())"
        typealias InitFn = @convention(c) () -> Void
        unsafeBitCast(sym_init!, to: InitFn.self)()
        lastError = nil
        return true
    }

    func loadGame(path: String) -> Bool {
        guard isLibretro, let loadSym = sym_load_game else {
            lastError = "Core missing retro_load_game"
            return false
        }
        let ok = path.withCString { cPath -> Bool in
            let ptrSize = MemoryLayout<UnsafeRawPointer?>.size
            let intSize = MemoryLayout<Int>.size
            var buf = [UInt8](repeating: 0, count: ptrSize * 3 + intSize)
            withUnsafeBytes(of: Optional(cPath)) { src in
                for i in 0..<min(src.count, ptrSize) { buf[i] = src[i] }
            }
            typealias LoadGameFn = @convention(c) (UnsafeRawPointer?) -> Bool
            return buf.withUnsafeBytes { raw in
                unsafeBitCast(loadSym, to: LoadGameFn.self)(raw.baseAddress)
            }
        }
        if !ok {
            lastError = "retro_load_game failed (need BIOS? bad ROM?)"
            return false
        }
        startRunLoop()
        return true
    }

    private func startRunLoop() {
        stopRunLoop()
        isRunning = true
        runTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.runFrame() }
        }
    }

    private func stopRunLoop() {
        runTimer?.invalidate()
        runTimer = nil
        isRunning = false
    }

    func runFrame() {
        guard let runSym = sym_run else { return }
        typealias RunFn = @convention(c) () -> Void
        unsafeBitCast(runSym, to: RunFn.self)()
    }

    func reset() {
        guard let resetSym = sym_reset else { return }
        typealias ResetFn = @convention(c) () -> Void
        unsafeBitCast(resetSym, to: ResetFn.self)()
    }

    func unloadGame() {
        stopRunLoop()
        guard let unloadSym = sym_unload_game else { return }
        typealias UnloadFn = @convention(c) () -> Void
        unsafeBitCast(unloadSym, to: UnloadFn.self)()
    }

    func unload() {
        stopRunLoop()
        FrameBuffer.shared.clear()
        if isLibretro {
            unloadGame()
            if let deinitSym = sym_deinit {
                typealias DeinitFn = @convention(c) () -> Void
                unsafeBitCast(deinitSym, to: DeinitFn.self)()
            }
        }
        if let h = handle { dlclose(h); handle = nil }
        loadedCoreName = nil
        isLibretro = false
        coreVersion = nil
        sym_init = nil; sym_deinit = nil; sym_api_version = nil
        sym_load_game = nil; sym_unload_game = nil; sym_run = nil; sym_reset = nil
        sym_set_video = nil; sym_set_input_poll = nil; sym_set_input_state = nil
        sym_set_audio = nil; sym_set_audio_batch = nil; sym_set_env = nil
    }

    private func displayName(_ raw: String) -> String {
        var s = raw
        if let last = s.split(separator: "/").last { s = String(last) }
        return s.replacingOccurrences(of: ".dylib", with: "")
    }

    deinit { if let h = handle { dlclose(h) } }
}

// MARK: - C callbacks

private let RETRO_ENVIRONMENT_SET_PIXEL_FORMAT: UInt32 = 10
private let RETRO_PIXEL_FORMAT_RGB565: Int32 = 2
private var g_useRGB565 = false

private func coreEnvironment(cmd: UInt32, data: UnsafeMutableRawPointer?) -> Bool {
    if cmd == RETRO_ENVIRONMENT_SET_PIXEL_FORMAT, let data {
        let fmt = data.assumingMemoryBound(to: Int32.self).pointee
        g_useRGB565 = (fmt == RETRO_PIXEL_FORMAT_RGB565)
        return true
    }
    return false
}

private func coreVideoRefresh(data: UnsafeRawPointer?, width: UInt32, height: UInt32, pitch: Int) {
    guard data != nil, width > 0, height > 0 else { return }
    FrameBuffer.shared.update(
        data: data, width: Int(width), height: Int(height),
        pitch: pitch, isRGB565: g_useRGB565
    )
}

private func coreInputPoll() {}
private func coreInputState(_ port: UInt32, _ device: UInt32, _ index: UInt32, _ id: UInt32) -> Int16 { 0 }
private func coreAudioSample(_ left: Int16, _ right: Int16) {}
private func coreAudioBatch(_ data: UnsafePointer<Int16>?, _ frames: Int) -> Int { frames }
