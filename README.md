# k1emu

**All-types ROMs emulator for iOS** with phone-as-controller + TV/AirPlay mode.

## Features

- Beautiful main library + Install ROM (file / URL)
- FAQ (`?`)
- Long-press game actions (Info / Tweaks / Multitask / Delete)
- Tweak Loader
- Settings (background & joystick colors + cool presets)
- **Liquid Glass** on iOS 18+ / 26+
- **TV / AirPlay / external display mode**: TV shows the pure game (full screen), phone becomes the full controller (no overlapping UI)
- **System-specific controller skins**:
  - **PSP / PS1 / PS2** → △ ○ × □ (PlayStation symbols + correct colours)
  - **Nintendo (NES/SNES/N64/GBA/NDS…)** → X Y A B with classic colours
  - **Sega** → A B X Y / C Z style labels
  - **Default** → Xbox A B X Y
- **Much larger GAME panel** in phone mode — controls stay in the side gutters so they never cover the video in portrait or landscape
- Dual analog sticks + Browser / CHIP-8 pad centre panel
- Three mode dots: Cursor · CHIP-8 pad · Browser
- Mouse/Cursor mode, in-game menu, haptics, spring animations

## Status

UI + architecture are production-ready and match the requested controller / TV behaviour.

**Honest note on “real” emulation:**  
Real multi-system libretro cores (PPSSPP, mGBA, melonDS, PCSX-ReARMed, etc.) are **not** shipped in this repo — they are large binary/C++ projects.  
Only the built-in **CHIP-8** core is fully functional right now. For every other system the app loads a placeholder so the UI, input, TV mode, save paths and controller all work end-to-end.  

Drop real `ios-arm64` `.dylib` cores into `Cores/` (or the app’s Documents/Cores folder) and the existing `CoreLoader` will pick them up automatically.

## Build IPA with GitHub Actions

1. Go to **Actions** tab
2. Run the workflow **Build IPA**
3. Download the artifact `k1emu.ipa`

> For a properly signed IPA you must add your Apple Developer certificate + provisioning profile as repository secrets (`BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`, `BUILD_PROVISION_PROFILE_BASE64`, `KEYCHAIN_PASSWORD`).  
> Without them the workflow still produces an unsigned IPA that you can resign locally with `codesign` / AltStore / Sideloadly / TrollStore etc.

## Project Structure

```
k1emu/
├── k1emu/
│   ├── App/
│   ├── Models/
│   ├── Views/
│   │   ├── Main/
│   │   ├── Emu/
│   │   ├── Tweak/
│   │   ├── Settings/
│   │   ├── Controller/          ← photo-accurate layout + modes
│   │   └── Components/
│   ├── Services/
│   └── Resources/
├── Cores/                       ← drop ios-arm64 .dylib cores here
├── .github/workflows/
└── README.md
```

## Requirements

- Xcode 16+
- iOS 17.0+ deployment target (Liquid Glass / advanced materials use iOS 18+ availability checks)

## License

Private – all rights reserved.
