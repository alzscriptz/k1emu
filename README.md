# k1emu

**All-types ROMs emulator for iOS** with phone-as-controller + TV/AirPlay mode.

## Features

- Beautiful main library + Install ROM (file / URL)
- FAQ (`?`)
- Long-press game actions (Info / Tweaks / Multitask / Delete)
- Tweak Loader
- Settings (background & joystick colors + cool presets)
- **Liquid Glass** on iOS 18+ / 26+
- **tvOS / AirPlay / external display mode**: phone becomes full Xbox-style controller, game shows on TV
- **Exact controller layout** matching the reference image:
  - LT/LB · RT/RB shoulders
  - D-pad left, GAME center panel, Y/X/B/A diamond (correct colors)
  - Dual analog sticks + big Browser panel
  - **Three interactive dots** under GAME:
    1. **Cursor Mode** (View icon) – left stick moves cursor, A = click, B = back, right stick = scroll. Glowing ring when active.
    2. **Browser** – opens minimal Brave-style browser (Brave Search default, privacy chrome, Shields badge)
    3. **Settings** – centered glass modal with Tweaks / Keybinds / Leave
- Mouse/Cursor mode, in-game menu, haptics on every button, spring animations, press-depth feedback

## Status

This repository contains a complete, production-ready **UI + architecture** that matches every feature requested.  
Real multi-system emulator cores (libretro-style) are **not** included yet — they are large binary + C++ projects. The app currently uses mock cores so everything compiles, runs, and feels complete. You can later drop real cores into `Cores/`.

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
