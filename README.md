# k1emu

**All-types ROMs emulator for iOS** with:
- Beautiful main library + Install ROM (file / URL)
- FAQ (`?`)
- Long-press game actions (Info / Tweaks / Multitask / Delete)
- Tweak Loader
- Settings (background & joystick colors + cool presets)
- Liquid Glass on iOS 18+ / 26+
- **tvOS / AirPlay / external display mode**: phone becomes full Xbox-style controller, game shows on TV
- Mouse mode (two Windows buttons), Browser mode, in-game menu (Tweaks / Speed / Keybinds / Quit)

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
│   │   ├── Controller/
│   │   └── Components/
│   ├── Services/
│   └── Resources/
├── .github/workflows/build-ipa.yml
└── README.md
```

## Requirements

- Xcode 16+
- iOS 17.0+ deployment target (Liquid Glass / advanced materials use iOS 18+ availability checks)

## License

Private – all rights reserved.
