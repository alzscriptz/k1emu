import Foundation
import Darwin

/// Libretro host. NDS uses Direct Boot (no user BIOS required for App Store).
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
    private var romDataHolder: Data?

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
                try? fm.copyItem(at: f, to: dest)
            }
        }
        _ = systemDirectory
        _ = saveDirectory
        g_systemDirPath = systemDirectory.path
        g_saveDirPath = saveDirectory.path
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
        case "nes", "fds", "unf": return "NES"
        case "sfc", "smc": return "SNES"
        case "n64", "z64", "v64": return "N64"
        case "md", "gen", "smd": return "Genesis"
        case "sms", "gg": return "SMS"
        case "cue", "pbp", "chd": return "PS1"
        case "iso", "cso": return "PSP"
        case "gdi", "cdi": return "DC"
        case "vb": return "VB"
        case "ws", "wsc": return "WS"
        case "min": return "POKEMINI"
        case "ch8", "c8": return "CHIP8"
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
        logLines = []
        prepareBundledCores()

        let key = system.uppercased()
        log("Core for \(key)")

        let candidates = CoreLoader.systemCoreMap[key] ?? []
        let keywords = CoreLoader.systemScanKeywords[key] ?? [key.lowercased()]
        var lastDlError = ""

        for dir in searchDirs {
            for base in candidates {
                let url = dir.appendingPathComponent("\(base).dylib")
                triedPaths.append(url.path)
                if FileManager.default.fileExists(atPath: url.path) {
                    if open(path: url.path, name: base) {
                        log("OK \(base)")
                        return true
                    }
                    lastDlError = lastError ?? ""
                }
            }
        }

        for dir in searchDirs {
            guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { continue }
            for f in files where f.pathExtension == "dylib" {
                let lower = f.lastPathComponent.lowercased()
                if keywords.contains(where: { lower.contains($0) }) {
                    triedPaths.append(f.path)
                    if open(path: f.path, name: displayName(f.lastPathComponent)) {
                        log("OK scan \(f.lastPathComponent)")
                        return true
                    }
                    lastDlError = lastError ?? ""
                }
            }
        }

        let found = triedPaths.filter { FileManager.default.fileExists(atPath: $0) }
        lastError = found.isEmpty
            ? "This system isn't available yet"
            : "Couldn't start emulator (\(lastDlError))"
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
            lastError = "Invalid core"
            dlclose(h); handle = nil
            return false
        }

        isLibretro = true
        g_systemDirPath = systemDirectory.path
        g_saveDirPath = saveDirectory.path

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
        coreVersion = "API \(unsafeBitCast(sym_api_version!, to: ApiVersionFn.self)())"
        typealias InitFn = @convention(c) () -> Void
        unsafeBitCast(sym_init!, to: InitFn.self)()
        lastError = nil
        return true
    }

    func loadGame(path: String) -> Bool {
        guard isLibretro, let loadSym = sym_load_game else {
            lastError = "Emulator not ready"
            return false
        }
        guard FileManager.default.fileExists(atPath: path) else {
            lastError = "Game file not found"
            return false
        }
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)), !data.isEmpty else {
            lastError = "Couldn't read game file"
            return false
        }

        romDataHolder = data
        log("ROM \(data.count) bytes")

        let ok = data.withUnsafeBytes { romBuf -> Bool in
            guard let dataPtr = romBuf.baseAddress else { return false }
            return path.withCString { cPath -> Bool in
                let ptrSize = MemoryLayout<UnsafeRawPointer?>.size
                let intSize = MemoryLayout<Int>.size
                var buf = [UInt8](repeating: 0, count: ptrSize * 3 + intSize)
                withUnsafeBytes(of: Optional(cPath)) { src in
                    for i in 0..<min(src.count, ptrSize) { buf[i] = src[i] }
                }
                withUnsafeBytes(of: Optional(dataPtr)) { src in
                    for i in 0..<min(src.count, ptrSize) { buf[ptrSize + i] = src[i] }
                }
                withUnsafeBytes(of: data.count) { src in
                    for i in 0..<min(src.count, intSize) { buf[ptrSize * 2 + i] = src[i] }
                }
                typealias LoadFn = @convention(c) (UnsafeRawPointer?) -> Bool
                let fn = unsafeBitCast(loadSym, to: LoadFn.self)
                return buf.withUnsafeBytes { raw in fn(raw.baseAddress) }
            }
        }

        if !ok {
            lastError = "Couldn't load this game. Try another file or core."
            romDataHolder = nil
            return false
        }

        log("Game loaded (direct boot)")
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
        guard let s = sym_reset else { return }
        typealias F = @convention(c) () -> Void
        unsafeBitCast(s, to: F.self)()
    }

    func unloadGame() {
        stopRunLoop()
        if let s = sym_unload_game {
            typealias F = @convention(c) () -> Void
            unsafeBitCast(s, to: F.self)()
        }
        romDataHolder = nil
    }

    func unload() {
        stopRunLoop()
        FrameBuffer.shared.clear()
        InputBridge.shared.clearAll()
        if isLibretro {
            unloadGame()
            if let s = sym_deinit {
                typealias F = @convention(c) () -> Void
                unsafeBitCast(s, to: F.self)()
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

// MARK: - C env / video (Direct Boot defaults — App Store, no user BIOS)

private var g_systemDirPath = ""
private var g_saveDirPath = ""
private var g_systemDirCStr: UnsafeMutablePointer<CChar>?
private var g_saveDirCStr: UnsafeMutablePointer<CChar>?
private var g_useRGB565 = false
private var g_varValueCStr: UnsafeMutablePointer<CChar>?

private let ENV_GET_SYSTEM_DIRECTORY: UInt32 = 9
private let ENV_SET_PIXEL_FORMAT: UInt32 = 10
private let ENV_GET_CAN_DUPE: UInt32 = 3
private let ENV_GET_VARIABLE: UInt32 = 15
private let ENV_SET_VARIABLES: UInt32 = 16
private let ENV_GET_VARIABLE_UPDATE: UInt32 = 17
private let ENV_GET_SAVE_DIRECTORY: UInt32 = 19
private let ENV_SET_INPUT_DESCRIPTORS: UInt32 = 11
private let ENV_SET_CONTROLLER_INFO: UInt32 = 35
private let PIXEL_RGB565: Int32 = 2

private let kCoreOptionDefaults: [String: String] = [
    "melonds_boot_directly": "enabled",
    "melonds_console_mode": "DS",
    "melonds_use_fw_settings": "disable",
    "melonds_ds_boot_mode": "direct",
    "melonds_ds_console_mode": "ds",
    "melondsds_boot_mode": "direct",
    "melondsds_console_mode": "ds",
    "melonds_firmware": "none",
    "melonds_ds_firmware": "none"
]

private func updateCString(_ existing: inout UnsafeMutablePointer<CChar>?, _ path: String) -> UnsafePointer<CChar>? {
    existing?.deallocate()
    existing = nil
    let utf = path.utf8CString
    let p = UnsafeMutablePointer<CChar>.allocate(capacity: utf.count)
    for (i, c) in utf.enumerated() { p[i] = c }
    existing = p
    return UnsafePointer(p)
}

private struct RetroVariable {
    var key: UnsafePointer<CChar>?
    var value: UnsafePointer<CChar>?
}

private func coreEnvironment(cmd: UInt32, data: UnsafeMutableRawPointer?) -> Bool {
    switch cmd {
    case ENV_SET_PIXEL_FORMAT:
        if let data {
            g_useRGB565 = data.assumingMemoryBound(to: Int32.self).pointee == PIXEL_RGB565
            return true
        }
        return false

    case ENV_GET_SYSTEM_DIRECTORY:
        guard let data else { return false }
        let ptr = updateCString(&g_systemDirCStr, g_systemDirPath)
        data.assumingMemoryBound(to: UnsafePointer<CChar>?.self).pointee = ptr
        return ptr != nil

    case ENV_GET_SAVE_DIRECTORY:
        guard let data else { return false }
        let ptr = updateCString(&g_saveDirCStr, g_saveDirPath)
        data.assumingMemoryBound(to: UnsafePointer<CChar>?.self).pointee = ptr
        return ptr != nil

    case ENV_GET_CAN_DUPE:
        data?.assumingMemoryBound(to: Bool.self).pointee = true
        return true

    case ENV_GET_VARIABLE_UPDATE:
        data?.assumingMemoryBound(to: Bool.self).pointee = false
        return true

    case ENV_SET_VARIABLES, ENV_SET_INPUT_DESCRIPTORS, ENV_SET_CONTROLLER_INFO:
        return true

    case ENV_GET_VARIABLE:
        guard let data else { return false }
        let v = data.assumingMemoryBound(to: RetroVariable.self)
        guard let keyPtr = v.pointee.key else { return false }
        let key = String(cString: keyPtr)
        guard let value = kCoreOptionDefaults[key] else { return false }
        g_varValueCStr?.deallocate()
        let utf = value.utf8CString
        let p = UnsafeMutablePointer<CChar>.allocate(capacity: utf.count)
        for (i, c) in utf.enumerated() { p[i] = c }
        g_varValueCStr = p
        v.pointee.value = UnsafePointer(p)
        return true

    default:
        return false
    }
}

private func coreVideoRefresh(data: UnsafeRawPointer?, width: UInt32, height: UInt32, pitch: Int) {
    guard let data, width > 0, height > 0 else { return }
    FrameBuffer.shared.update(
        data: data, width: Int(width), height: Int(height),
        pitch: pitch, isRGB565: g_useRGB565
    )
}

private func coreInputPoll() {}
private func coreInputState(_ port: UInt32, _ device: UInt32, _ index: UInt32, _ id: UInt32) -> Int16 {
    InputBridge.shared.state(port: port, device: device, index: index, id: id)
}
private func coreAudioSample(_ left: Int16, _ right: Int16) {}
private func coreAudioBatch(_ data: UnsafePointer<Int16>?, _ frames: Int) -> Int { frames }
