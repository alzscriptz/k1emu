# k1emu

**iOS ROM library and emulator frontend** with an experimental phone-as-controller + external-display mode.

## Current status — read before using

This project is a work in progress, not a complete multi-system emulator. A polished screen or a listed system does not mean that system is playable.

- A built-in CHIP-8 interpreter is present.
- Other systems require a compatible, correctly built libretro core to be bundled with the app or installed in the app's Cores directory.
- Core availability, ROM loading, audio, input mapping, save states, and system compatibility must be verified per core. Do not assume every ROM or system works.
- The gameplay view should not report a fabricated FPS value. Performance must be measured from actual rendered frames and tested on a device.
- External-display and controller UI features are not proof that the connected display, browser, tweaks, or every advertised action is fully functional.

## Gameplay

- Immersive, edge-to-edge game viewport where a compatible core produces frames.
- On-screen menu controls are hidden by default in the immersive play view and can be revealed by tapping.
- Video scaling must be selected deliberately: aspect-fill uses the whole viewport but may crop edges; aspect-fit preserves the full frame but can leave unused space. The right choice depends on the game and system.
- iOS safe areas, device rotation, touch input, and external display behavior need testing across supported devices and orientations.

## Supported emulation

The built-in CHIP-8 core is the only in-repository standalone interpreter. Other systems depend on external libretro cores. The core loader's system map describes candidate core names; it is not a compatibility guarantee. Users must provide ROMs and any legally required system files themselves.

## Build IPA with GitHub Actions

1. Open the **Actions** tab.
2. Run the **Build IPA** workflow.
3. Download the generated artifact if the workflow succeeds.

A properly signed IPA requires the appropriate Apple Developer certificate and provisioning profile secrets. An unsigned build must be signed through a suitable local workflow before installation.

## Project structure

- `k1emu/App/` — application state and entry point
- `k1emu/Models/` — library and settings models
- `k1emu/Views/` — library, gameplay, controller, and settings UI
- `k1emu/Services/` — core loading, framebuffer, input, and CHIP-8 interpreter
- `Cores/` — instructions for supplying compatible core binaries
- `.github/workflows/` — build and release workflows

## Requirements

- Xcode 16+
- iOS 17.0+

## License

Private — all rights reserved.
