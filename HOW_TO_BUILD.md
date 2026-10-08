# How to get a real .ipa

## Option A – GitHub Actions (recommended)

1. Go to the repository → **Actions** → **Build IPA** → **Run workflow**
2. Wait for the macOS job to finish (real `xcodebuild`)
3. Download the artifact **k1emu-ipa** or grab it from the Release
4. The IPA is **unsigned**. Install with:
   - AltStore / SideStore
   - TrollStore (if your device supports it)
   - KSign / other sideload tools
   - or resign with your Apple Developer certificate

The workflow now runs on `macos-latest`, generates the Xcode project with XcodeGen, builds for `generic/platform=iOS` with signing disabled, and packages a proper `Payload/k1emu.app`.

## Option B – Local Xcode (best for development)

```bash
brew install xcodegen
git clone https://github.com/alzscriptz/k1emu.git
cd k1emu
xcodegen generate
open k1emu.xcodeproj
```

1. Select your team in Signing & Capabilities (or leave unsigned)
2. Product → Archive → Distribute App → Ad Hoc / Development → Export IPA

## Option C – Fully signed CI IPA

Add these repository secrets:

- `BUILD_CERTIFICATE_BASE64` – base64 of your .p12
- `P12_PASSWORD`
- `BUILD_PROVISION_PROFILE_BASE64` – base64 of the .mobileprovision
- `KEYCHAIN_PASSWORD` – any password for the temporary keychain

Then extend the workflow with the standard keychain + codesign steps.

---

## Real cores

1. Obtain **iphoneos arm64** `.dylib` cores (libretro or custom).
2. Drop them into the `Cores/` folder.
3. Rebuild (Actions or local). They get copied into `k1emu.app/Frameworks/`.
4. `CoreLoader` will `dlopen` them, bind `retro_*` symbols, call `retro_init`, and expose `loadGame` / `runFrame`.

See `Cores/README.md` for suggested filenames and ABI notes.

No cores are bundled by default (size + licensing).
