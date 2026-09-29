# Emulator Cores (dylibs)

Put your core `.dylib` files here (or under `k1emu/Frameworks/` after build).

## Expected names (optional, CoreLoader looks for these)

| System | Suggested dylib name |
|--------|----------------------|
| NDS    | `libnds.dylib` or `nds_libretro.dylib` |
| GBA    | `libgba.dylib` |
| GB/GBC | `libgb.dylib` |
| NES    | `libnes.dylib` |
| SNES   | `libsnes.dylib` |
| N64    | `libn64.dylib` |
| PS1    | `libpsx.dylib` |

## How it works

1. You build / obtain the core as a **ios-arm64** `.dylib`
2. Drop it in this folder (or send it and we commit it)
3. CI / packaging copies every `*.dylib` into `Payload/k1emu.app/Frameworks/`
4. At runtime `CoreLoader` uses `dlopen` on `Bundle.main.privateFrameworksPath` / `Frameworks/`

## ABI note

Cores must be built for **iphoneos arm64** (not simulator, not macOS).
If you use libretro-style cores, export the standard `retro_*` symbols when possible.
