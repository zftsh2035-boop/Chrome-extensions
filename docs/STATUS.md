# Build status

- Target: Android `armeabi-v7a` (`target_cpu="arm"`).
- Browser: public Chromium, not Google Chrome.
- Extensions: upstream experimental Desktop Android implementation selected by
  `is_desktop_android=true`.
- Initial inspected revision: Chromium `154.0.8024.0`, commit
  `812b24985650ef7aca3da9b95c879166dd66bdf7`, commit position `1685227`.
- Package name: `org.chromium.chrome`.
- Minimum Android API is controlled by upstream Desktop Android configuration;
  Chromium 154 generated API 29 manifests in the first local attempt.

The first temporary local build reached late V8/Blink compilation but its
runtime was destroyed before the APK was packaged. This repository replaces
that fragile setup with a reproducible Actions build and durable logs/artifacts.

## Known limitations

- Desktop Android extensions are explicitly marked experimental by upstream
  Chromium and may crash or regress between revisions.
- Google Chrome branding, Google-internal sources, Widevine, and Chrome Sync
  are not available in a public Chromium checkout.
- A GitHub-hosted standard runner may be close to its six-hour and disk limits.
  The workflow frees unused preinstalled SDKs and disables expensive LTO/PGO.
  If it still exceeds the limit, use a GitHub larger runner or a self-hosted
  Linux x86_64 runner without changing the repository or signing identity.
