import Foundation

extension CoreLoader {
    /// Preferred libretro core basenames per system (order = preference).
    static let systemCoreMap: [String: [String]] = [
        "NDS": [
            "melondsds_libretro", "melonds_libretro", "desmume_libretro",
            "noods_libretro", "libnds", "melonds", "melondsds"
        ],
        "GBA": [
            "mgba_libretro", "gpsp_libretro", "vbam_libretro",
            "vba_next_libretro", "mednafen_gba_libretro", "libgba", "mgba"
        ],
        "GB": [
            "gambatte_libretro", "sameboy_libretro", "gearboy_libretro", "libgb"
        ],
        "GBC": [
            "gambatte_libretro", "sameboy_libretro", "gearboy_libretro", "libgb"
        ],
        "NES": [
            "fceumm_libretro", "nestopia_libretro", "quicknes_libretro",
            "mesen_libretro", "libnes"
        ],
        "SNES": [
            "snes9x_libretro", "snes9x2010_libretro", "snes9x2005_plus_libretro",
            "bsnes_libretro", "mednafen_snes_libretro", "libsnes"
        ],
        "N64": [
            "mupen64plus_next_libretro", "parallel_n64_libretro", "libn64"
        ],
        "Genesis": [
            "genesis_plus_gx_libretro", "picodrive_libretro"
        ],
        "SMS": [
            "genesis_plus_gx_libretro", "picodrive_libretro", "gearsystem_libretro"
        ],
        "PS1": [
            "pcsx_rearmed_libretro", "swanstation_libretro", "mednafen_psx_libretro"
        ],
        "PSP": ["ppsspp_libretro"],
        "DC": ["flycast_libretro"],
        "GC": ["dolphin_libretro", "dolphin"],
        "WII": ["dolphin_libretro", "dolphin"],
        "VB": ["mednafen_vb_libretro"],
        "WS": ["mednafen_wswan_libretro"],
        "POKEMINI": ["pokemini_libretro"],
        "CHIP8": []
    ]

    /// Keywords used when scanning Frameworks for a matching dylib.
    static let systemScanKeywords: [String: [String]] = [
        "NDS": ["melon", "desmume", "noods", "nds"],
        "GBA": ["mgba", "gpsp", "vbam", "vba_next", "mednafen_gba", "gba"],
        "GB": ["gambatte", "sameboy", "gearboy"],
        "GBC": ["gambatte", "sameboy", "gearboy"],
        "NES": ["fceumm", "nestopia", "quicknes", "mesen"],
        "SNES": ["snes9x", "bsnes", "mednafen_snes"],
        "N64": ["mupen", "parallel_n64"],
        "Genesis": ["genesis", "picodrive"],
        "SMS": ["genesis", "picodrive", "gearsystem"],
        "PS1": ["pcsx", "swanstation", "mednafen_psx"],
        "PSP": ["ppsspp"],
        "DC": ["flycast"],
        "GC": ["dolphin"],
        "WII": ["dolphin"],
        "VB": ["mednafen_vb"],
        "WS": ["wswan"],
        "POKEMINI": ["pokemini"]
    ]
}
