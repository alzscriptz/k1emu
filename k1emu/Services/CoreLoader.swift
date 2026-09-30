import Foundation
import Darwin

/// Loads emulator cores packaged as iOS frameworks.
/// iOS device builds must package dynamic code as a .framework rather than a loose .dylib.
@MainActor
final class CoreLoader: ObservableObject {
    static let shared = CoreLoader()

    @Published private(set) var loadedCoreName: String?
    @Published private(set) var lastError: String?

    private var handle: UnsafeMutableRawPointer?

    private let coreNames: [String: [String]] = [
        "NDS": ["libnds", "nds_libretro", "libretro_nds", "desmume"],
        "GBA": ["libgba", "gba_libretro", "mgba"],
        "GB":  ["libgb", "gb_libretro", "sameboy", "gambatte"],
        "GBC": ["libgb", "gbc_libretro", "sameboy", "gambatte"],
        "NES": ["libnes", "nes_libretro", "fceumm", "nestopia"],
        "SNES": ["libsnes", "snes_libretro", "snes9x"],
        "N64": ["libn64", "n64_libretro", "mupen64plus"],
        "PS1": ["libpsx", "psx_libretro", "pcsx"],
        "Genesis": ["libgenesis", "genesis_libretro", "picodrive"],
        "SMS": ["libsms", "sms_libretro"],
        "Other": ["libcore", "core"]
    ]

    private var searchDirs: [URL] {
        var dirs: [URL] = []

        if let fw = Bundle.main.privateFrameworksURL {
            dirs.append(fw)
        }

        let bundle = Bundle.main.bundleURL
        dirs.append(bundle.appendingPathComponent("Frameworks"))
        dirs.append(bundle.appendingPathComponent("Cores"))
        dirs.append(bundle.appendingPathComponent("Resources/Cores"))
        if let res = Bundle.main.resourceURL {
            dirs.append(res.appendingPathComponent("Frameworks"))
            dirs.append(res.appendingPathComponent("Cores"))
            dirs.append(res)
        }

        if let exe = Bundle.main.executableURL?.deletingLastPathComponent() {
            dirs.append(exe.appendingPathComponent("Frameworks"))
            dirs.append(exe.appendingPathComponent("Cores"))
            dirs.append(exe)
        }

        var seen = Set<String>()
        return dirs.filter { seen.insert($0.path).inserted }
    }

    func listAvailableCores() -> [String] {
        var names = Set<String>()

        for dir in searchDirs {
            guard let files = try? FileManager.default.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil
            ) else { continue }

            for file in files {
                if file.pathExtension == "framework" {
                    let binary = file.appendingPathComponent(file.deletingPathExtension().lastPathComponent)
                    if FileManager.default.fileExists(atPath: binary.path) {
                        names.insert(file.lastPathComponent)
                    }
                } else if file.pathExtension == "dylib" {
                    names.insert(file.lastPathComponent)
                }
            }
        }

        return names.sorted()
    }

    @discardableResult
    func loadCore(for system: String) -> Bool {
        unload()
        lastError = nil

        let key = system.uppercased()
        var candidates = coreNames[key] ?? []
        candidates.append(contentsOf: coreNames["Other"] ?? [])
        candidates.insert("lib\(key.lowercased())", at: 0)

        for dir in searchDirs {
            for base in candidates {
                let framework = dir.appendingPathComponent("\(base).framework")
                let frameworkBinary = framework.appendingPathComponent(base)
                if FileManager.default.fileExists(atPath: frameworkBinary.path),
                   open(path: frameworkBinary.path, name: "\(base).framework") {
                    return true
                }

                let dylib = dir.appendingPathComponent("\(base).dylib")
                if FileManager.default.fileExists(atPath: dylib.path),
                   open(path: dylib.path, name: dylib.lastPathComponent) {
                    return true
                }

                let bare = dir.appendingPathComponent(base)
                if FileManager.default.fileExists(atPath: bare.path),
                   open(path: bare.path, name: bare.lastPathComponent) {
                    return true
                }
            }

            if let files = try? FileManager.default.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil
            ) {
                for framework in files where framework.pathExtension == "framework" {
                    let name = framework.deletingPathExtension().lastPathComponent
                    let binary = framework.appendingPathComponent(name)
                    if name.lowercased().contains(key.lowercased()),
                       FileManager.default.fileExists(atPath: binary.path),
                       open(path: binary.path, name: framework.lastPathComponent) {
                        return true
                    }
                }
            }
        }

        lastError = "No \(system) core is bundled. The iOS build must contain an ios-arm64 core framework."
        loadedCoreName = nil
        return false
    }

    @discardableResult
    func loadCore(named fileName: String) -> Bool {
        unload()
        lastError = nil

        for dir in searchDirs {
            let direct = dir.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: direct.path),
               open(path: direct.path, name: fileName) {
                return true
            }

            let base = direct.deletingPathExtension().lastPathComponent
            let frameworkBinary = dir
                .appendingPathComponent("\(base).framework")
                .appendingPathComponent(base)
            if FileManager.default.fileExists(atPath: frameworkBinary.path),
               open(path: frameworkBinary.path, name: "\(base).framework") {
                return true
            }
        }

        lastError = "\(fileName) not found in app bundle"
        return false
    }

    private func open(path: String, name: String) -> Bool {
        guard let h = dlopen(path, RTLD_NOW | RTLD_GLOBAL) else {
            if let err = dlerror() {
                lastError = String(cString: err)
            } else {
                lastError = "dlopen failed for \(name)"
            }
            return false
        }

        handle = h
        loadedCoreName = name
        lastError = nil
        return true
    }

    func unload() {
        if let h = handle {
            dlclose(h)
            handle = nil
        }
        loadedCoreName = nil
    }

    func symbol<T>(_ name: String) -> T? {
        guard let h = handle else { return nil }
        guard let sym = dlsym(h, name) else { return nil }
        return unsafeBitCast(sym, to: T.self)
    }

    deinit {
        if let h = handle {
            dlclose(h)
        }
    }
}
