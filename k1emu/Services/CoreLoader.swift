import Foundation
import Darwin

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

        lastError = "No dylib for \(system)"
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

    private func displayName(_ raw: String) -> String {
        var s = raw
        if let last = s.split(separator: "/").last { s = String(last) }
        s = s.replacingOccurrences(of: ".framework", with: "")
        s = s.replacingOccurrences(of: ".dylib", with: "")
        if s.lowercased() == "libdns" { s = "libnds" }
        return s
    }

    private func open(path: String, name: String) -> Bool {
        guard let h = dlopen(path, RTLD_NOW) else {
            if let err = dlerror() {
                lastError = String(cString: err)
            } else {
                lastError = "dlopen failed"
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
        if let h = handle { dlclose(h) }
    }
}
