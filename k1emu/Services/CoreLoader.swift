import Foundation
import Darwin

/// CoreLoader – dlopen ios-arm64 cores. Copies bundle dylibs to Documents/Cores
/// (LiveContainer / sideload often cannot RTLD_NOW from Frameworks).
@MainActor
final class CoreLoader: ObservableObject {
    static let shared = CoreLoader()

    @Published private(set) var loadedCoreName: String?
    @Published private(set) var lastError: String?
    @Published private(set) var isLibretro: Bool = false
    @Published private(set) var coreVersion: String?
    @Published private(set) var triedPaths: [String] = []

    private var handle: UnsafeMutableRawPointer?
    private var sym_init: UnsafeMutableRawPointer?
    private var sym_deinit: UnsafeMutableRawPointer?
    private var sym_api_version: UnsafeMutableRawPointer?
    private var sym_load_game: UnsafeMutableRawPointer?
    private var sym_unload_game: UnsafeMutableRawPointer?
    private var sym_run: UnsafeMutableRawPointer?
    private var sym_reset: UnsafeMutableRawPointer?

    private let coreNames: [String: [String]] = [
        "NDS": ["melondsds_libretro", "melondsds", "melonds", "libnds", "nds_libretro", "desmume"]
    ]

    private var documentsCores: URL {
        let u = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Cores", isDirectory: true)
        try? FileManager.default.createDirectory(at: u, withIntermediateDirectories: true)
        return u
    }

    /// Call once at launch: copy any Frameworks/*.dylib into Documents/Cores
    func prepareBundledCores() {
        let fm = FileManager.default
        var sources: [URL] = []

        if let exe = Bundle.main.executableURL?.deletingLastPathComponent() {
            sources.append(exe.appendingPathComponent("Frameworks"))
            sources.append(exe)
        }
        if let res = Bundle.main.resourceURL {
            sources.append(res.appendingPathComponent("Frameworks"))
            sources.append(res.appendingPathComponent("Cores"))
        }
        if let pf = Bundle.main.privateFrameworksURL {
            sources.append(pf)
        }

        for dir in sources {
            guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { continue }
            for f in files where f.pathExtension == "dylib" {
                let dest = documentsCores.appendingPathComponent(f.lastPathComponent)
                if fm.fileExists(atPath: dest.path) {
                    // refresh if bundle is newer / different size
                    let srcSize = (try? f.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                    let dstSize = (try? dest.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                    if srcSize == dstSize { continue }
                    try? fm.removeItem(at: dest)
                }
                try? fm.copyItem(at: f, to: dest)
            }
        }
    }

    private var searchDirs: [URL] {
        var dirs: [URL] = [documentsCores]
        if let exe = Bundle.main.executableURL?.deletingLastPathComponent() {
            dirs.append(exe.appendingPathComponent("Frameworks"))
            dirs.append(exe)
        }
        if let res = Bundle.main.resourceURL {
            dirs.append(res.appendingPathComponent("Frameworks"))
            dirs.append(res.appendingPathComponent("Cores"))
        }
        if let pf = Bundle.main.privateFrameworksURL { dirs.append(pf) }
        return dirs
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
        // Always try melon names for NDS
        if key == "NDS" {
            candidates = ["melondsds_libretro", "libnds", "melonds", "melondsds", "nds_libretro"]
        }

        var lastDlError = ""

        for dir in searchDirs {
            for base in candidates {
                let url = dir.appendingPathComponent("\(base).dylib")
                triedPaths.append(url.path)
                if FileManager.default.fileExists(atPath: url.path) {
                    if open(path: url.path, name: base) {
                        return true
                    }
                    lastDlError = lastError ?? ""
                }
            }
            // any melon* / *nds* dylib in folder
            if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for f in files where f.pathExtension == "dylib" {
                    let lower = f.lastPathComponent.lowercased()
                    if key == "NDS" && (lower.contains("melon") || lower.contains("nds") || lower.contains("desmume")) {
                        triedPaths.append(f.path)
                        if open(path: f.path, name: displayName(f.lastPathComponent)) {
                            return true
                        }
                        lastDlError = lastError ?? ""
                    }
                }
            }
        }

        let found = triedPaths.filter { FileManager.default.fileExists(atPath: $0) }
        if found.isEmpty {
            lastError = "No NDS dylib found. Expected melondsds_libretro.dylib in Frameworks or Documents/Cores"
        } else {
            lastError = "dlopen failed: \(lastDlError). Tried: \(found.map { ($0 as NSString).lastPathComponent }.joined(separator: ", "))"
        }
        loadedCoreName = nil
        return false
    }

    private func open(path: String, name: String) -> Bool {
        // Clear previous error
        _ = dlerror()

        // Prefer LAZY first (missing optional deps), then NOW
        var h = dlopen(path, RTLD_LAZY | RTLD_LOCAL)
        if h == nil {
            let err1 = dlerror().map { String(cString: $0) } ?? "nil"
            _ = dlerror()
            h = dlopen(path, RTLD_NOW | RTLD_LOCAL)
            if h == nil {
                let err2 = dlerror().map { String(cString: $0) } ?? "nil"
                lastError = "\(err2) [also LAZY: \(err1)]"
                return false
            }
        }

        handle = h
        loadedCoreName = name

        sym_api_version = dlsym(h, "retro_api_version")
        sym_init        = dlsym(h, "retro_init")
        sym_deinit      = dlsym(h, "retro_deinit")
        sym_load_game   = dlsym(h, "retro_load_game")
        sym_unload_game = dlsym(h, "retro_unload_game")
        sym_run         = dlsym(h, "retro_run")
        sym_reset       = dlsym(h, "retro_reset")

        if sym_api_version != nil && sym_init != nil {
            isLibretro = true
            typealias ApiVersionFn = @convention(c) () -> Int32
            let apiFn = unsafeBitCast(sym_api_version!, to: ApiVersionFn.self)
            coreVersion = "libretro API \(apiFn())"
            typealias InitFn = @convention(c) () -> Void
            unsafeBitCast(sym_init!, to: InitFn.self)()
        } else {
            isLibretro = false
            coreVersion = "loaded (no retro_* symbols)"
        }

        lastError = nil
        return true
    }

    func loadGame(path: String) -> Bool {
        guard isLibretro, let loadSym = sym_load_game else {
            lastError = "Core missing retro_load_game"
            return false
        }
        // Proper retro_game_info: { path*, data*, size, meta* }
        return path.withCString { cPath in
            struct RetroGameInfo {
                var path: UnsafePointer<CChar>?
                var data: UnsafeRawPointer?
                var size: Int
                var meta: UnsafePointer<CChar>?
            }
            var info = RetroGameInfo(path: cPath, data: nil, size: 0, meta: nil)
            typealias LoadGameFn = @convention(c) (UnsafePointer<RetroGameInfo>?) -> Bool
            let loadFn = unsafeBitCast(loadSym, to: LoadGameFn.self)
            let ok = withUnsafePointer(to: &info) { loadFn($0) }
            if !ok { lastError = "retro_load_game returned false" }
            return ok
        }
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
        guard let unloadSym = sym_unload_game else { return }
        typealias UnloadFn = @convention(c) () -> Void
        unsafeBitCast(unloadSym, to: UnloadFn.self)()
    }

    func unload() {
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
    }

    private func displayName(_ raw: String) -> String {
        var s = raw
        if let last = s.split(separator: "/").last { s = String(last) }
        return s.replacingOccurrences(of: ".dylib", with: "")
    }

    deinit { if let h = handle { dlclose(h) } }
}
