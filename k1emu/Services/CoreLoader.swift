import Foundation
import Darwin

// MARK: - CoreLoader (libretro-ready)
// Uses raw C function pointers so we stay ABI-compatible without
// putting non-ObjC-representable Swift structs into @convention(c).

@MainActor
final class CoreLoader: ObservableObject {
    static let shared = CoreLoader()

    @Published private(set) var loadedCoreName: String?
    @Published private(set) var lastError: String?
    @Published private(set) var isLibretro: Bool = false
    @Published private(set) var coreVersion: String?

    private var handle: UnsafeMutableRawPointer?

    // Raw C symbols (looked up via dlsym)
    private var sym_init: UnsafeMutableRawPointer?
    private var sym_deinit: UnsafeMutableRawPointer?
    private var sym_api_version: UnsafeMutableRawPointer?
    private var sym_get_system_info: UnsafeMutableRawPointer?
    private var sym_load_game: UnsafeMutableRawPointer?
    private var sym_unload_game: UnsafeMutableRawPointer?
    private var sym_run: UnsafeMutableRawPointer?
    private var sym_reset: UnsafeMutableRawPointer?

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

    // MARK: - Open + bind symbols

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

        // Look up standard libretro entry points as raw pointers
        sym_api_version     = dlsym(h, "retro_api_version")
        sym_init            = dlsym(h, "retro_init")
        sym_deinit          = dlsym(h, "retro_deinit")
        sym_get_system_info = dlsym(h, "retro_get_system_info")
        sym_load_game       = dlsym(h, "retro_load_game")
        sym_unload_game     = dlsym(h, "retro_unload_game")
        sym_run             = dlsym(h, "retro_run")
        sym_reset           = dlsym(h, "retro_reset")

        if sym_api_version != nil && sym_init != nil {
            isLibretro = true

            // Call retro_api_version() -> Int32
            typealias ApiVersionFn = @convention(c) () -> Int32
            let apiFn = unsafeBitCast(sym_api_version, to: ApiVersionFn.self)
            let ver = apiFn()
            coreVersion = "libretro API \(ver)"

            // Call retro_init()
            typealias InitFn = @convention(c) () -> Void
            let initFn = unsafeBitCast(sym_init, to: InitFn.self)
            initFn()

            // Best-effort: try to read library name via retro_get_system_info
            // (layout is stable enough for name/version strings)
            if let infoSym = sym_get_system_info {
                // We only need the first two char* fields
                struct MinimalInfo {
                    var library_name: UnsafePointer<CChar>?
                    var library_version: UnsafePointer<CChar>?
                }
                typealias GetInfoFn = @convention(c) (UnsafeMutablePointer<MinimalInfo>?) -> Void
                let getInfo = unsafeBitCast(infoSym, to: GetInfoFn.self)
                var info = MinimalInfo(library_name: nil, library_version: nil)
                getInfo(&info)
                if let lib = info.library_name {
                    loadedCoreName = String(cString: lib)
                }
                if let verStr = info.library_version {
                    coreVersion = String(cString: verStr)
                }
            }
        } else {
            isLibretro = false
            coreVersion = "custom / unknown ABI"
        }

        lastError = nil
        return true
    }

    // MARK: - Public core control

    func loadGame(path: String) -> Bool {
        guard isLibretro, let loadSym = sym_load_game else {
            lastError = "Core does not support retro_load_game"
            return false
        }
        // Minimal retro_game_info: path, data, size, meta
        struct GameInfo {
            var path: UnsafePointer<CChar>?
            var data: UnsafeRawPointer?
            var size: Int
            var meta: UnsafePointer<CChar>?
        }
        typealias LoadGameFn = @convention(c) (UnsafePointer<GameInfo>?) -> Bool
        let loadFn = unsafeBitCast(loadSym, to: LoadGameFn.self)
        return path.withCString { cPath in
            var info = GameInfo(path: cPath, data: nil, size: 0, meta: nil)
            return loadFn(&info)
        }
    }

    func runFrame() {
        guard let runSym = sym_run else { return }
        typealias RunFn = @convention(c) () -> Void
        let runFn = unsafeBitCast(runSym, to: RunFn.self)
        runFn()
    }

    func reset() {
        guard let resetSym = sym_reset else { return }
        typealias ResetFn = @convention(c) () -> Void
        let resetFn = unsafeBitCast(resetSym, to: ResetFn.self)
        resetFn()
    }

    func unloadGame() {
        guard let unloadSym = sym_unload_game else { return }
        typealias UnloadFn = @convention(c) () -> Void
        let unloadFn = unsafeBitCast(unloadSym, to: UnloadFn.self)
        unloadFn()
    }

    func unload() {
        if isLibretro {
            unloadGame()
            if let deinitSym = sym_deinit {
                typealias DeinitFn = @convention(c) () -> Void
                let deinitFn = unsafeBitCast(deinitSym, to: DeinitFn.self)
                deinitFn()
            }
        }
        if let h = handle {
            dlclose(h)
            handle = nil
        }
        loadedCoreName = nil
        isLibretro = false
        coreVersion = nil
        sym_init = nil
        sym_deinit = nil
        sym_api_version = nil
        sym_get_system_info = nil
        sym_load_game = nil
        sym_unload_game = nil
        sym_run = nil
        sym_reset = nil
    }

    private func displayName(_ raw: String) -> String {
        var s = raw
        if let last = s.split(separator: "/").last { s = String(last) }
        s = s.replacingOccurrences(of: ".framework", with: "")
        s = s.replacingOccurrences(of: ".dylib", with: "")
        if s.lowercased() == "libdns" { s = "libnds" }
        return s
    }

    deinit {
        if let h = handle { dlclose(h) }
    }
}
