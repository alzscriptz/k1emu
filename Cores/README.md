# Emulator Cores (ios-arm64 dylibs)

Drop real cores here. The CI and local build will copy every `*.dylib` into `k1emu.app/Frameworks/`.

## How to get cores

You need **iphoneos arm64** `.dylib` files (not simulator, not macOS).

Popular sources / build methods:
- Build libretro cores with an iOS toolchain (theos / cctools / Xcode custom target)
- Community prebuilt packs (search for "libretro ios dylib" or specific core names)
- Compile yourself from https://github.com/libretro

## Suggested filenames (CoreLoader auto-detects)

| System   | Suggested names                                      |
|----------|------------------------------------------------------|
| NDS      | `libnds.dylib`, `nds_libretro.dylib`, `melonds.dylib` |
| GBA      | `libgba.dylib`, `mgba.dylib`, `gba_libretro.dylib`   |
| GB/GBC   | `libgb.dylib`, `sameboy.dylib`, `gambatte.dylib`     |
| NES      | `libnes.dylib`, `fceumm.dylib`, `nestopia.dylib`     |
| SNES     | `libsnes.dylib`, `snes9x.dylib`                      |
| N64      | `libn64.dylib`, `mupen64plus.dylib`                  |
| PS1      | `libpsx.dylib`, `pcsx_rearmed.dylib`                 |
| Genesis  | `libgenesis.dylib`, `picodrive.dylib`                |
| PSP      | `libpsp.dylib`, `ppsspp.dylib`                       |
| Dreamcast| `libdc.dylib`, `flycast.dylib`                       |
| Arcade   | `fbneo.dylib`, `mame.dylib`                          |

## Runtime behaviour

`CoreLoader` now:
1. Searches `Frameworks/`, `Cores/`, app bundle, and Documents
2. `dlopen`s the first matching dylib
3. Binds standard **libretro** symbols (`retro_init`, `retro_load_game`, `retro_run`, …)
4. Calls `retro_init` and reads library name/version
5. Exposes `loadGame(path:)`, `runFrame()`, `reset()`, `unloadGame()`

If the dylib is **not** libretro it still loads (custom ABI can be added later).

## Quick test

1. Put e.g. `mgba.dylib` (ios-arm64) into this folder
2. Push → GitHub Actions builds a new IPA with the core inside Frameworks
3. Sideload → start a GBA game → CoreLoader will report the core name

No cores are bundled by default (size + licensing).
