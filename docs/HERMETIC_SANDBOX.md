# Hermetic sandbox workaround

The original interactive build environment denied the local sockets used by
the pinned legacy `gsutil` package. This caused dependency downloads to fail in
`multiprocessing.Manager()` before any Chromium compilation.

The patch in `patches/gsutil-hermetic-no-multiprocessing.patch` exposes
`GSUTIL_DISABLE_MULTIPROCESSING=1`, which selects gsutil's existing thread-only
fallback. A writable boto `state_dir` is also required in a read-only home
directory.

Normal GitHub-hosted runners do not need this patch. It is preserved solely so
the exact local workaround is not lost.
