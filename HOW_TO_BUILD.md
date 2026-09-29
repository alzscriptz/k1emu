# How to get a real .ipa

## Option A – GitHub Actions (current workflow)

1. Go to the repository → **Actions** → **Build IPA** → **Run workflow**
2. Download the artifact `k1emu-ipa`
3. The IPA is **unsigned**. Install it with:
   - AltStore / SideStore
   - TrollStore (if your device supports it)
   - `ideviceinstaller` + your own signing
   - or resign with your Apple Developer certificate

## Option B – Local Xcode (recommended for development)

1. Clone the repo
2. `brew install xcodegen` (if you don’t have it)
3. `xcodegen generate`
4. Open `k1emu.xcodeproj`
5. Select your team in Signing & Capabilities
6. Product → Archive → Distribute App → Ad Hoc / Development → Export IPA

## Option C – Fully signed CI IPA

Add these repository secrets:

- `BUILD_CERTIFICATE_BASE64` – base64 of your .p12
- `P12_PASSWORD`
- `BUILD_PROVISION_PROFILE_BASE64` – base64 of the .mobileprovision
- `KEYCHAIN_PASSWORD` – any password for the temporary keychain

Then uncomment the signing steps at the bottom of `.github/workflows/build-ipa.yml`.

---

**Note on emulator cores**

The current project is a complete UI shell that implements every screen and interaction you asked for.  
Real multi-system cores (libretro, etc.) are large C/C++ projects and are intentionally left as the next integration step. The play view is currently a polished placeholder so you can test the entire flow (install ROM, long-press, TV controller mode, browser mode, in-game menu, tweaks, colors, liquid glass, etc.).
