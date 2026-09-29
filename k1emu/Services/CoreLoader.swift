import Foundation
import Darwin

/// Loads emulator core dylibs from the app bundle Frameworks folder.
/// You provide the .dylib (ios-arm64); we package it into the IPA.
@MainActor
final class CoreLoader: ObservableObject {
    static let shared = CoreLoader()

    @Published private(set) var loadedCoreName: String?
    @Published private(set) var lastError: String?

    private var handle: UnsafeMutableRawPointer?

    /// Map system id -> possible dylib base names to try
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

    /// Search paths inside the .app for dylibs
    private var searchDirs: [URL] {
        var dirs: [URL] = []
        if let fw = Bundle.main.privateFrameworksURL {
            dirs.append(fw)
        }
        if let res = Bundle.main.resourceURL {
            dirs.append(res.appendingPathComponent("Frameworks"))
            dirs.append(res.appendingPathComponent("Cores"))
            dirs.append(res)
        }
        // Also check executable directory
        if let exe = Bundle.main.executableURL?.deletingLastPathComponent() {
            dirs.append(exe.appendingPathComponent("Frameworks"))
            dirs.append(exe)
        }
        return dirs
    }

    /// List every .dylib found in the bundle (for Settings / debug)
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

    /// Try to load a core for the given system. Returns true if dlopen succeeded.
    @discardableResult
    func loadCore(for system: String) -> Bool {
        unload()
        lastError = nil

        let key = system.uppercased()
        var candidates = coreNames[key] ?? []
        candidates.append(contentsOf: coreNames["Other"] ?? [])
        // Also try exact system name
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
                        if open(path: url.path, name: url.lastPathComponent) {
                            return true
                        }
                    }
                }
            }
            // Fallback: any dylib in folder whose name contains system token
            if let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
                for f in files where f.pathExtension == "dylib" {
                    let lower = f.lastPathComponent.lowercased()
                    if lower.contains(key.lowercased()) || key == "OTHER" {
                        if open(path: f.path, name: f.lastPathComponent) {
                            return true
                        }
                    }
                }
            }
        }

        lastError = "No dylib found for \(system). Drop an ios-arm64 .dylib into Frameworks/ or Cores/."
        loadedCoreName = nil
        return false
    }

    /// Load a specific dylib by file name (e.g. "libnds.dylib")
    @discardableResult
    func loadCore(named fileName: String) -> Bool {
        unload()
        lastError = nil
        for dir in searchDirs {
            let url = dir.appendingPathComponent(fileName)
            if FileManager.default.fileExists(atPath: url.path) {
                return open(path: url.path, name: fileName)
            }
        }
        lastError = "\(fileName) not found in app bundle"
        return false
    }

    private func open(path: String, name: String) -> Bool {
        // RTLD_NOW | RTLD_GLOBAL
        let flags = RTLD_NOW
        guard let h = dlopen(path, flags) else {
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

    /// Resolve a C symbol from the loaded dylib (e.g. retro_init)
    func symbol<T>(_ name: String) -> T? {
        guard let h = handle else { return nil }
        guard let sym = dlsym(h, name) else { return nil }
        return unsafeBitCast(sym, to: T.self)
    }

    deinit {
        if let h = handle { dlclose(h) }
    }
}
