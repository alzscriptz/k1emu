import Foundation
import Darwin

// MARK: - Minimal libretro ABI (so real cores can be dlopened)

typealias retro_init_t              = @convention(c) () -> Void
typealias retro_deinit_t            = @convention(c) () -> Void
typealias retro_api_version_t       = @convention(c) () -> Int32
typealias retro_get_system_info_t   = @convention(c) (UnsafeMutablePointer<retro_system_info>?) -> Void
typealias retro_get_system_av_info_t = @convention(c) (UnsafeMutablePointer<retro_system_av_info>?) -> Void
typealias retro_set_environment_t   = @convention(c) (@escaping retro_environment_t) -> Void
typealias retro_set_video_refresh_t = @convention(c) (@escaping retro_video_refresh_t) -> Void
typealias retro_set_audio_sample_t  = @convention(c) (@escaping retro_audio_sample_t) -> Void
typealias retro_set_audio_sample_batch_t = @convention(c) (@escaping retro_audio_sample_batch_t) -> Void
typealias retro_set_input_poll_t    = @convention(c) (@escaping retro_input_poll_t) -> Void
typealias retro_set_input_state_t   = @convention(c) (@escaping retro_input_state_t) -> Void
typealias retro_load_game_t         = @convention(c) (UnsafePointer<retro_game_info>?) -> Bool
typealias retro_unload_game_t       = @convention(c) () -> Void
typealias retro_run_t               = @convention(c) () -> Void
typealias retro_reset_t             = @convention(c) () -> Void

typealias retro_environment_t      = @convention(c) (UInt32, UnsafeMutableRawPointer?) -> Bool
typealias retro_video_refresh_t     = @convention(c) (UnsafeRawPointer?, UInt32, UInt32, Int) -> Void
typealias retro_audio_sample_t      = @convention(c) (Int16, Int16) -> Void
typealias retro_audio_sample_batch_t = @convention(c) (UnsafePointer<Int16>?, Int) -> Int
typealias retro_input_poll_t        = @convention(c) () -> Void
typealias retro_input_state_t       = @convention(c) (UInt32, UInt32, UInt32, UInt32) -> Int16

struct retro_system_info {
    var library_name: UnsafePointer<CChar>?
    var library_version: UnsafePointer<CChar>?
    var valid_extensions: UnsafePointer<CChar>?
    var need_fullpath: Bool
    var block_extract: Bool
}

struct retro_game_info {
    var path: UnsafePointer<CChar>?
    var data: UnsafeRawPointer?
    var size: Int
    var meta: UnsafePointer<CChar>?
}

struct retro_game_geometry {
    var base_width: UInt32
    var base_height: UInt32
    var max_width: UInt32
    var max_height: UInt32
    var aspect_ratio: Float
}

struct retro_system_timing {
    var fps: Double
    var sample_rate: Double
}

struct retro_system_av_info {
    var geometry: retro_game_geometry
    var timing: retro_system_timing
}

// MARK: - CoreLoader

@MainActor
final class CoreLoader: ObservableObject {
    static let shared = CoreLoader()

    @Published private(set) var loadedCoreName: String?
    @Published private(set) var lastError: String?
    @Published private(set) var isLibretro: Bool = false
    @Published private(set) var coreVersion: String?

    private var handle: UnsafeMutableRawPointer?

    // Cached libretro symbols
    private var fn_init: retro_init_t?
    private var fn_deinit: retro_deinit_t?
    private var fn_api_version: retro_api_version_t?
    private var fn_get_system_info: retro_get_system_info_t?
    private var fn_load_game: retro_load_game_t?
    private var fn_unload_game: retro_unload_game_t?
    private var fn_run: retro_run_t?
    private var fn_reset: retro_reset_t?
    private var fn_set_environment: retro_set_environment_t?
    private var fn_set_video_refresh: retro_set_video_refresh_t?
    private var fn_set_audio_sample: retro_set_audio_sample_t?
    private var fn_set_audio_sample_batch: retro_set_audio_sample_batch_t?
    private var fn_set_input_poll: retro_set_input_poll_t?
    private var fn_set_input_state: retro_set_input_state_t?

    private let coreNames: [String: [String]] = [
        "NDS":     ["libnds", "nds_libretro", "desmume", "melonds"],
        "GBA":     ["libgba", "gba_libretro", "mgba", "vba_next"],
        "GB":      ["libgb", "gb_libretro", "sameboy", "gambatte"],
        "GBC":     ["libgb", "gbc_libretro", "sameboy", "gambatte"],
        "NES":     ["libnes", "nes_libretro", "fceumm", "nestopia", "quicknes"],
        "SNES":    ["libsnes", "snes_libretro", "snes9x", "bsnes"],
        "N64":     ["libn64", "n64_libretro", "mupen64plus", "parallel_n64"],
        "PS1":     ["libpsx", "psx_libretro", "pcsx_rearmed", "beetle_psx"],
        "Genesis": ["libgenesis", "genesis_libretro", "picodrive", "genesis_plus_gx"],
        "SMS":     ["libsms", "sms_libretro", "picodrive"],
        "PSP":     ["libpsp", "psp_libretro", "ppsspp"],
        "DC":      ["libdc", "dc_libretro", "flycast"],
        "Arcade":  ["libarcade", "fbneo", "mame"],
        "Other":   ["libcore", "core"]
    ]

    private var searchDirs: [URL] {
        var dirs: [URL] = []
        if let fw = Bundle.main.privateFrameworksURL { dirs.append(fw) }
        if let res = Bundle.main.resourceURL {
            dirs.append(res.appendingPathComponent("Frameworks"))
            dirs.append(res.appendingPathComponent("Cores"))
            dirs.append(res)
        }
        if let exe = Bundle.main.executableURL?.deletingLastPathComponent() {
            dirs.append(exe.appendingPathComponent("Frameworks"))
            dirs.append(exe)
        }
        // Also look next to the app for sideload convenience
        dirs.append(URL(fileURLWithPath: "/var/mobile/Documents"))
        return dirs
    }

    func listAvailableCores() -> [String] {
        var names: [String] = []
        for dir in searchDirs {
            guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { continue }
            for f in files where f.pathExtension == "dylib" || f.pathExtension == "framework" {
                names.append(f.lastPathComponent)
            }
        }
        return Array(Set(names)).sorted()
    }

    @discardableResult
    func loadCore(for system: String) -> Bool {
        unload()
        lastError = nil
        isLibretro = false
        coreVersion = nil

        let key = system.uppercased()
        var candidates = coreNames[key] ?? []
        candidates.append(contentsOf: coreNames["Other"] ?? [])
        candidates.insert("lib\(key.lowercased())", at: 0)

        for dir in searchDirs {
            for base in candidates {
                let urls = [
                    dir.appendingPathComponent("\(base).dylib"),
                    dir.appendingPathComponent(base),
                    dir.appendingPathComponent("\(base).framework/\(base)")
                ]
                for url in urls {
                    if FileManager.default.fileExists(atPath: url.path) {
                        if open(path: url.path, name: displayName(url.lastPathComponent)) {
                            return true
                        }
                    }
                }
            }
            // Fallback: any dylib that contains the system name
            if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for f in files where f.pathExtension == "dylib" {
                    let lower = f.lastPathComponent.lowercased()
                    if lower.contains(key.lowercased()) || key == "OTHER" {
                        if open(path: f.path, name: displayName(f.lastPathComponent)) {
                            return true
                        }
                    }
                }
            }
        }

        lastError = "No dylib for \(system). Drop an ios-arm64 .dylib into Cores/ or Frameworks/"
        loadedCoreName = nil
        return false
    }

    @discardableResult
    func loadCore(named fileName: String) -> Bool {
        unload()
        lastError = nil
        for dir in searchDirs {
            let url = dir.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: url.path) {
                return open(path: url.path, name: displayName(fileName))
            }
        }
        lastError = "\(fileName) not found"
        return false
    }

    // MARK: - Open + bind libretro symbols

    private func open(path: String, name: String) -> Bool {
        guard let h = dlopen(path, RTLD_NOW) else {
            if let err = dlerror() {
                lastError = String(cString: err)
            } else {
                lastError = "dlopen failed for \(name)"
            }
            return false
        }
        handle = h
        loadedCoreName = name

        // Try to bind standard libretro entry points
        fn_api_version          = symbol("retro_api_version")
        fn_init                 = symbol("retro_init")
        fn_deinit               = symbol("retro_deinit")
        fn_get_system_info      = symbol("retro_get_system_info")
        fn_load_game            = symbol("retro_load_game")
        fn_unload_game          = symbol("retro_unload_game")
        fn_run                  = symbol("retro_run")
        fn_reset                = symbol("retro_reset")
        fn_set_environment      = symbol("retro_set_environment")
        fn_set_video_refresh    = symbol("retro_set_video_refresh")
        fn_set_audio_sample     = symbol("retro_set_audio_sample")
        fn_set_audio_sample_batch = symbol("retro_set_audio_sample_batch")
        fn_set_input_poll       = symbol("retro_set_input_poll")
        fn_set_input_state      = symbol("retro_set_input_state")

        if fn_api_version != nil && fn_init != nil {
            isLibretro = true
            let ver = fn_api_version?() ?? 0
            coreVersion = "libretro API \(ver)"

            // Wire minimal environment + callbacks so the core can init
            fn_set_environment?({ cmd, data in
                // Minimal stub – real implementation later
                return false
            })
            fn_set_video_refresh?({ _, _, _, _ in })
            fn_set_audio_sample?({ _, _ in })
            fn_set_audio_sample_batch?({ _, frames in frames })
            fn_set_input_poll?({ })
            fn_set_input_state?({ _, _, _, _ in 0 })

            fn_init?()

            if var info = Optional(retro_system_info(library_name: nil, library_version: nil, valid_extensions: nil, need_fullpath: false, block_extract: false)) {
                fn_get_system_info?(&info)
                if let lib = info.library_name {
                    loadedCoreName = String(cString: lib)
                }
                if let verStr = info.library_version {
                    coreVersion = String(cString: verStr)
                }
            }
        } else {
            // Not a libretro core – still loaded, custom ABI later
            isLibretro = false
            coreVersion = "custom / unknown ABI"
        }

        lastError = nil
        return true
    }

    // MARK: - Public core control

    func loadGame(path: String) -> Bool {
        guard isLibretro, let load = fn_load_game else {
            lastError = "Core does not support retro_load_game"
            return false
        }
        return path.withCString { cPath in
            var info = retro_game_info(path: cPath, data: nil, size: 0, meta: nil)
            return load(&info)
        }
    }

    func runFrame() {
        fn_run?()
    }

    func reset() {
        fn_reset?()
    }

    func unloadGame() {
        fn_unload_game?()
    }

    func unload() {
        if isLibretro {
            fn_unload_game?()
            fn_deinit?()
        }
        if let h = handle {
            dlclose(h)
            handle = nil
        }
        loadedCoreName = nil
        isLibretro = false
        coreVersion = nil
        fn_init = nil
        fn_deinit = nil
        fn_api_version = nil
        fn_get_system_info = nil
        fn_load_game = nil
        fn_unload_game = nil
        fn_run = nil
        fn_reset = nil
        fn_set_environment = nil
        fn_set_video_refresh = nil
        fn_set_audio_sample = nil
        fn_set_audio_sample_batch = nil
        fn_set_input_poll = nil
        fn_set_input_state = nil
    }

    private func displayName(_ raw: String) -> String {
        var s = raw
        if let last = s.split(separator: "/").last { s = String(last) }
        s = s.replacingOccurrences(of: ".framework", with: "")
        s = s.replacingOccurrences(of: ".dylib", with: "")
        if s.lowercased() == "libdns" { s = "libnds" }
        return s
    }

    func symbol<T>(_ name: String) -> T? {
        guard let h = handle else { return nil }
        guard let sym = dlsym(h, name) else { return nil }
        return unsafeBitCast(sym, to: T.self)
    }

    deinit {
        // Note: unload() is @MainActor; just close the handle here
        if let h = handle { dlclose(h) }
    }
}
