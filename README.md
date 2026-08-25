# Chromium for Android ARMv7 with extensions

This repository builds public Chromium for 32-bit Android ARM
(`armeabi-v7a`) with Chromium's upstream experimental Desktop Android extension
implementation.

It does **not** patch a Google Chrome APK and does not carry an old Kiwi or
Ultimatum extension patch. The relevant upstream relationship in Chromium 154
is:

```text
is_desktop_android=true
  -> enable_desktop_android_extensions=true
  -> enable_extensions_core=true
```

The resulting application uses the stable package name `org.chromium.chrome`.
Every published APK must be signed with the same private key so Android can
install future engine updates over the existing browser profile.

## Build from GitHub Actions

1. Add the two repository secrets documented in [SECURITY.md](SECURITY.md).
2. Open **Actions → Build ARMv7 Chromium → Run workflow**.
3. Leave `Chromium ref` empty to build the pinned revision, or select
   `Build current Chromium main` for the newest source revision.
4. A successful run uploads the signed APK as an Actions artifact. When
   `Publish GitHub release` is enabled, it also creates a release suitable for
   Obtainium.

The scheduled weekly run builds current Chromium main. Only after the complete
build, signing, and verification succeed does it update
`config/chromium.env` and publish a release.

## Local Linux build

The supported host is Linux x86_64 with at least 16 GiB RAM and roughly
60–100 GiB free disk space. Run:

```bash
./scripts/bootstrap.sh
./scripts/build.sh
```

To sign locally, export `ANDROID_KEYSTORE_PASSWORD` and optionally
`ANDROID_KEY_ALIAS`, then run:

```bash
./scripts/sign-apk.sh path/to/keystore.p12
./scripts/verify-apk.sh dist/Chromium-ARMv7-Extensions-signed.apk
```

## Updating on Android

Obtainium can follow this repository's Releases page. Since package name and
certificate remain constant, Android installs a newer version in place and
keeps the browser profile and installed extensions.

## Honest limitations

- Extension support is an unstable upstream prototype, not a supported Chrome
  for Android feature.
- Public Chromium cannot include Google Chrome branding or private Google
  services. Widevine DRM is not bundled.
- Chrome Web Store installation behavior and individual extensions must be
  tested on the produced APK; compilation alone does not prove full desktop
  compatibility.

See [docs/STATUS.md](docs/STATUS.md) for the exact inspected revision and build
history.
