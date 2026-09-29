# k1emu

A polished iOS emulator shell focused on a clean, user-owned library and a controller-first external-display experience.

## What is in v1.5

- Branded K1 app icon in the IPA.
- Home stays empty until the user adds a ROM.
- ROM picker accepts generic Files/iCloud data, so unknown/new ROM extensions are not hidden.
- Persistent appearance, controller, FPS and TV settings.
- Reworked Settings control center with reset support.
- Real tweak-file storage in Documents/Tweaks plus import/create editor.
- Preset tweak templates are stored as actual files; game-specific cheat codes can be imported/edited instead of being silently faked.
- Live FPS HUD uses real display callbacks rather than random/simulated numbers.
- External displays get a dedicated full-screen game surface with the FPS HUD in the top-right.
- 4K output is reported only when the connected display actually exposes a 4K-class native mode.
- CI packages the latest libnds.dylib from the private alzscriptz/compiler release when COMPILER_TOKEN is available.

## Build

GitHub Actions generates the Xcode project with XcodeGen, builds an unsigned iOS IPA, uploads k1emu-ipa as an artifact, and publishes v1.5.0 from main.

For the private compiler repository, add a repository secret named COMPILER_TOKEN with permission to read the compiler release. The workflow falls back to the Actions token and continues without the core if that token cannot read the private repository.

The app still needs a renderer/core ABI bridge before it can display a real emulator framebuffer. CoreLoader can load compatible iOS arm64 dylibs, while the external-display shell, controller UI, ROM management and performance HUD are independent of that renderer.

## Project layout

- k1emu/App — app state and scene setup
- k1emu/Models — ROM, settings and tweak models
- k1emu/Services — ROM/tweak stores, core loader, FPS and external display services
- k1emu/Views — library, controller, settings, tweak and TV surfaces
- Cores — bundled emulator dylibs
- .github/workflows/build-ipa.yml — IPA CI

## Requirements

- iOS 17+
- Xcode/XcodeGen for local builds
- iOS arm64 dylibs for bundled emulator cores

Private project — all rights reserved.