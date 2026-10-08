import Foundation
import Darwin

/// Libretro host. melonDS REQUIRES info->data + size (not path-only).
@MainActor
final class CoreLoader: ObservableObject {
    static let shared = CoreLoader()

    @Published private(set) var loadedCoreName: String?
    @Published private(set) var lastError: String?
    @Published private(set) var isLibretro: Bool = false
    @Published private(set) var coreVersion: String?
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var triedPaths: [String] = []
    @Published private(set) var logLines: [String] = []

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

    /// Keep ROM bytes alive for the core (melonDS reads from this pointer)
    private var romDataHolder: Data?

    private let coreNames: [String: [String]] = [
        "NDS":  ["melondsds_libretro", "libnds", "melonds", "melondsds", "nds_libretro", "desmume"],
        "GBA":  ["mgba_libretro", "gba_libretro", "mgba", "vba_next"],
        "GB":   ["gambatte_libretro", "sameboy_libretro", "gb_libretro"],
        "GBC":  ["gambatte_libretro", "sameboy_libretro", "gbc_libretro"],
        "NES":  ["fceumm_libretro", "nestopia_libretro", "nes_libretro"],
        "SNES": ["snes9x_libretro", "bsnes_libretro", "snes_libretro"],
        "N64":  ["mupen64plus_next_libretro", "parallel_n64_libretro"],
        "CHIP8": []
    ]

    // MARK: - Directories (libretro env)

    var systemDirectory: URL {
        let u = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("system", isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    var saveDirectory: URL {
        let u = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("saves", isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    private var documentsCores: URL {
        let u = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Cores", isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    private func log(_ s: String) {
        logLines.append(s)
        if logLines.count > 40 { logLines.removeFirst(logLines.count - 40) }
        print("[k1emu] \(s)")
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
                do {
                    try fm.copyItem(at: f, to: dest)
                    log("Copied core → Documents/Cores/\(f.lastPathComponent)")
                } catch {
                    log("Copy core failed: \(error.localizedDescription)")
                }
            }
        }
        // Ensure system/saves exist for BIOS
        _ = systemDirectory
        _ = saveDirectory
    }

    func listAvailableCores() -> [String] {
        prepareBundledCores()
        var names: [String] = []
        for dir in searchDirs {
            guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { continue }
            for f in files where f.pathExtension == "dylib" { names.append(f.lastPathComponent) }
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
        case "nes", "fds", "unf", "nsf": return "NES"
        case "sfc", "smc", "fig": return "SNES"
        case "n64", "z64", "v64": return "N64"
        case "ch8", "c8": return "CHIP8"
        case "zip": return "NDS"
        default: return "Other"
        }
    }

    // MARK: - Load core

    @discardableResult
    func loadCore(for system: String) -> Bool {
        unload()
        lastError = nil
        isLibretro = false
        coreVersion = nil
        triedPaths = []
        logLines = []
        prepareBundledCores()

        let key = system.uppercased()
        log("Loading core for \(key)")

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
                    log("Trying \(url.lastPathComponent) in \(dir.lastPathComponent)")
                    if open(path: url.path, name: base) {
                        log("dlopen OK: \(base)")
                        return true
                    }
                    lastDlError = lastError ?? ""
                    log("dlopen fail: \(lastDlError)")
                }
            }
            if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for f in files where f.pathExtension == "dylib" {
                    let lower = f.lastPathComponent.lowercased()
                    let match = (key == "NDS" && (lower.contains("melon") || lower.contains("nds")))
                        || lower.contains(key.lowercased())
                    if match {
                        triedPaths.append(f.path)
                        if open(path: f.path, name: displayName(f.lastPathComponent)) {
                            log("dlopen OK (scan): \(f.lastPathComponent)")
                            return true
                        }
                        lastDlError = lastError ?? ""
                    }
                }
            }
        }

        let found = triedPaths.filter { FileManager.default.fileExists(atPath: $0) }
        lastError = found.isEmpty
            ? "No dylib for \(system). Put melondsds_libretro.dylib in Frameworks"
            : "dlopen failed: \(lastDlError)"
        log(lastError ?? "")
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
            lastError = "Not a libretro core (missing retro_init)"
            dlclose(h); handle = nil
            return false
        }

        isLibretro = true

        // Publish dirs for C environment callback
        CoreEnvBridge.shared.systemDir = systemDirectory.path
        CoreEnvBridge.shared.saveDir = saveDirectory.path

        // ORDER: environment → video/audio/input → init
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
        log("retro_init done")

        lastError = nil
        return true
    }

    // MARK: - Load game (CRITICAL: pass data + size for melonDS)

    func loadGame(path: String) -> Bool {
        guard isLibretro, let loadSym = sym_load_game else {
            lastError = "Core missing retro_load_game"
            log(lastError!)
            return false
        }

        guard FileManager.default.fileExists(atPath: path) else {
            lastError = "ROM file missing: \((path as NSString).lastPathComponent)"
            log(lastError!)
            return false
        }

        // Load entire ROM into memory — melonDS uses info->data / info->size
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            lastError = "Cannot read ROM"
            log(lastError!)
            return false
        }
        if data.isEmpty {
            lastError = "ROM is empty"
            return false
        }

        romDataHolder = data
        log("ROM size \(data.count) bytes")

        let ok = data.withUnsafeBytes { rawBuf -> Bool in
            guard let dataPtr = rawBuf.baseAddress else { return false }
            return path.withCString { cPath -> Bool in
                // struct retro_game_info { path*, data*, size, meta* }
                // arm64: 4 x 8-byte fields
                var info = RetroGameInfoC(
                    path: cPath,
                    data: dataPtr,
                    size: data.count,
                    meta: nil
                )
                typealias LoadGameFn = @convention(c) (UnsafePointer<RetroGameInfoC>?) -> Bool
                let fn = unsafeBitCast(loadSym, to: LoadGameFn.self)
                return withUnsafePointer(to: &info) { fn($0) }
            }
        }

        if !ok {
            lastError = "retro_load_game failed — need bios7.bin/bios9.bin in Files→k1emu→system? Or bad ROM"
            log(lastError!)
            romDataHolder = nil
            return false
        }

        log("retro_load_game OK — starting run loop")
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
        romDataHolder = nil
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
        romDataHolder = nil
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

// C-layout retro_game_info (must match libretro.h)
private struct RetroGameInfoC {
    var path: UnsafePointer<CChar>?
    var data: UnsafeRawPointer?
    var size: Int
    var meta: UnsafePointer<CChar>?
}

// Bridge for environment paths (C callback cannot capture self)
final class CoreEnvBridge {
    static let shared = CoreEnvBridge()
    var systemDir: String = ""
    var saveDir: String = ""
    // Keep C strings alive
    private var systemCStr: [CChar] = []
    private var saveCStr: [CChar] = []

    func systemCString() -> UnsafePointer<CChar>? {
        systemCStr = systemDir.cString(using: .utf8) ?? []
        return systemCStr.withUnsafeBufferPointer { $0.baseAddress }
    }

    func saveCString() -> UnsafePointer<CChar>? {
        saveCStr = saveDir.cString(using: .utf8) ?? []
        return saveCStr.withUnsafeBufferPointer { $0.baseAddress }
    }
}

// MARK: - Environment / video (global C functions)

private let RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY: UInt32 = 9
private let RETRO_ENVIRONMENT_SET_PIXEL_FORMAT: UInt32 = 10
private let RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY: UInt32 = 19
private let RETRO_ENVIRONMENT_SET_SUPPORT_NO_GAME: UInt32 = 18
private let RETRO_ENVIRONMENT_GET_LOG_INTERFACE: UInt32 = 27
private let RETRO_ENVIRONMENT_SET_VARIABLES: UInt32 = 16
private let RETRO_ENVIRONMENT_GET_VARIABLE: UInt32 = 15
private let RETRO_ENVIRONMENT_GET_VARIABLE_UPDATE: UInt32 = 17
private let RETRO_ENVIRONMENT_GET_CAN_DUPE: UInt32 = 3
private let RETRO_ENVIRONMENT_SET_INPUT_DESCRIPTORS: UInt32 = 11
private let RETRO_ENVIRONMENT_SET_CONTROLLER_INFO: UInt32 = 35
private let RETRO_ENVIRONMENT_GET_INPUT_BITMASKS: UInt32 = 51
private let RETRO_PIXEL_FORMAT_RGB565: Int32 = 2

private var g_useRGB565 = false

private func coreEnvironment(cmd: UInt32, data: UnsafeMutableRawPointer?) -> Bool {
    switch cmd {
    case RETRO_ENVIRONMENT_SET_PIXEL_FORMAT:
        if let data {
            let fmt = data.assumingMemoryBound(to: Int32.self).pointee
            g_useRGB565 = (fmt == RETRO_PIXEL_FORMAT_RGB565)
            return true
        }
        return false

    case RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY:
        // data is char **
        guard let data else { return false }
        let bridge = CoreEnvBridge.shared
        // Store path and write pointer
        bridge.systemCStr = (bridge.systemDir as NSString).utf8String.map { Array(UnsafeBufferPointer(start: $0, count: strlen($0) + 1)) } ?? []
        // Simpler: use strdup-like static storage
        let path = bridge.systemDir
        path.withCString { cstr in
            // Allocate permanent copy
            let len = strlen(cstr) + 1
            let copy = UnsafeMutablePointer<CChar>.allocate(capacity: len)
            memcpy(copy, cstr, len)
            data.assumingMemoryBound(to: UnsafePointer<CChar>?.self).pointee = UnsafePointer(copy)
        }
        return true

    case RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY:
        guard let data else { return false }
        let path = CoreEnvBridge.shared.saveDir
        path.withCString { cstr in
            let len = strlen(cstr) + 1
            let copy = UnsafeMutablePointer<CChar>.allocate(capacity: len)
            memcpy(copy, cstr, len)
            data.assumingMemoryBound(to: UnsafePointer<CChar>?.self).pointee = UnsafePointer(copy)
        }
        return true

    case RETRO_ENVIRONMENT_GET_CAN_DUPE:
        if let data {
            data.assumingMemoryBound(to: Bool.self).pointee = true
            return true
        }
        return false

    case RETRO_ENVIRONMENT_GET_VARIABLE_UPDATE:
        if let data {
            data.assumingMemoryBound(to: Bool.self).pointee = false
            return true
        }
        return false

    case RETRO_ENVIRONMENT_SET_VARIABLES,
         RETRO_ENVIRONMENT_SET_INPUT_DESCRIPTORS,
         RETRO_ENVIRONMENT_SET_CONTROLLER_INFO,
         RETRO_ENVIRONMENT_SET_SUPPORT_NO_GAME:
        return true

    case RETRO_ENVIRONMENT_GET_VARIABLE:
        return false

    case RETRO_ENVIRONMENT_GET_INPUT_BITMASKS:
        if let data {
            data.assumingMemoryBound(to: Bool.self).pointee = false
            return true
        }
        return false

    default:
        return false
    }
}

private func coreVideoRefresh(data: UnsafeRawPointer?, width: UInt32, height: UInt32, pitch: Int) {
    guard let data, width > 0, height > 0 else { return }
    FrameBuffer.shared.update(
        data: data,
        width: Int(width),
        height: Int(height),
        pitch: pitch,
        isRGB565: g_useRGB565
    )
}

private func coreInputPoll() {}
private func coreInputState(_ port: UInt32, _ device: UInt32, _ index: UInt32, _ id: UInt32) -> Int16 { 0 }
private func coreAudioSample(_ left: Int16, _ right: Int16) {}
private func coreAudioBatch(_ data: UnsafePointer<Int16>?, _ frames: Int) -> Int { frames }
