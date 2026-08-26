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
runtime was destroyed before the APK was packaged. Actions run 9 then compiled
`33001/62584` targets without a source error before GitHub cancelled the job at
its hard six-hour limit. The workflow now stops each compile slice early,
saves an 8 GiB ccache checkpoint, and queues a continuation pinned to the same
Chromium commit. Only the final slice can sign or publish an APK.

## Known limitations

- Desktop Android extensions are explicitly marked experimental by upstream
  Chromium and may crash or regress between revisions.
- Google Chrome branding, Google-internal sources, Widevine, and Chrome Sync
  are not available in a public Chromium checkout.
- A clean build exceeds the six-hour limit of a standard GitHub-hosted job.
  Compiler checkpoints allow it to continue in later free jobs, but a cold
  build can therefore need multiple workflow runs. A sufficiently powerful
  self-hosted Linux x86_64 runner can complete it in one longer job without
  changing the repository or signing identity.
