# PIN — installinstallmacos.py
Pinned: 2026-11-23, owner approval given in-chat 2026-11-23 13:02 EST (G-PIN opened by owner's tap).
Re-pinned: 2026-11-24 (test-3 repair, registry changes/0083) — the file now carries the Academy patch described below; the 2026-11-23 pin record is retained in git history and in changes/0075.

- Source: `munki/macadmin-scripts` (GitHub)
- Commit: `ae5d4a8ae782fb82541c686aa860ad0fa2d42c84` (2026-09-16, "Add new seed catalog URL to installinstallmacos.py (#136)")
- File: `installinstallmacos.py`, 32,397 bytes (patched; unpatched upstream is 29,631 bytes)
- SHA-256: `8df321573028266e19bb9d872097c0acf5ea63f0154fc058cd60208cb0a50f38` (computed 2026-11-24 over the patched file shipped in test-3)
- License: Apache License 2.0 — Copyright 2017-2022 Greg Neagle (per file header, read from the pinned copy). The Academy patch is Academy-original tooling under the Academy License (revocable); the file as a whole remains under its upstream license terms.
- Academy patch (2026-11-24, marked in-file): adds the `--version` argument and `select_product_for_version()` — exact-version match only; among exact matches the latest PostDate wins; no match exits 2 (fail closed, no substitution). Upstream at the pinned commit has no `--version` option (interactive menu only), so the launcher's `--version 10.15.7` call was rejected by argparse and the fetch stage of test-1/test-2 could never run. With `--version` given, the interactive menu is not presented. No other upstream behaviour is changed.
- Enforcement: `Upgrade-to-Catalina.command` recomputes the SHA-256 at runtime and refuses to run a mismatched fetcher.
