# Distro One-Click Upgrade — MacBookAir5,2 → Maximum macOS
BUILD STAMP — Built: 2026-11-23 12:57 EST · Build: scaffold-1 · Agent: Minion · Authorized: J. Spencer Smith, directive of 2026-11-23 (oneclick upgrade via Distro)

## Verdict — maximum version
Machine (owner screenshot 2026-11-23, ground truth; matches verified record 2026-11-08):
`MacBook Air (13-inch, Mid 2012)` = `MacBookAir5,2` · 1.7 GHz Intel Core i5 (Ivy Bridge) · 4 GB 1600 MHz DDR3 · Intel HD Graphics 4000 1536 MB · macOS High Sierra 10.13.6

| Lane | Ceiling | Status |
|---|---|---|
| **Official Apple** | **macOS Catalina 10.15.7** — Security Update 2022-005 (2022-07-20), final Catalina patch | Apple lists MacBook Air (Mid 2012) as Catalina-compatible; Big Sur 11 drops MacBookAir5,2. **This is the maximum supported version.** |
| Patched (OCLP) practical | macOS Monterey 12.7.6 via OpenCore Legacy Patcher | HD 4000 = 3802 Metal (Metal-capable, native to Monterey, root patches + lowered SIP required in Ventura+). Estate kit rule (2026-10-27): 4–8 GB RAM → Monterey, not Sequoia. **Not the default.** 4 GB RAM, SIP/root-patch cost, and no Apple support make this a gated owner decision, not a one-click default. |
| Patched theoretical | Sonoma/Sequoia via OCLP 2.x | Listed as OCLP-supported for MacBookAir5,x in general, but unusable as a recommendation at 4 GB on this rig. Excluded. |

**Default target shipped in this package: Catalina 10.15.7, official installer, no patcher, SIP intact.**

## Critical gate — this Air is the estate 10.13 rig
This machine is the sole High Sierra S4 rig for Distro / the uplift program (floor = 10.13 estate-wide).
An in-place upgrade destroys the 10.13 test surface. Therefore the one-click flow:
- installs Catalina to a **NEW APFS volume named `Catalina`** in the existing container,
- **never overwrites / erases the High Sierra volume in v1**,
- rollback = reboot holding Option → pick High Sierra. Deleting the Catalina volume is a separate, owner-only step.
If the internal SSD cannot hold both volumes (gate below), the flow stops — it does not improvise an in-place upgrade.

## Other hard facts that shape the flow
- Catalina is **64-bit only**: all 32-bit apps die on Catalina. Preflight must inventory 32-bit apps (`system_profiler SPApplicationsDataType`) and print them before the click arms anything.
- RAM: 4 GB = Catalina's exact minimum (4 GB). Passes, with no headroom claim.
- Storage gate: ≥40 GB free in the APFS container (installer app ~8.2 GB + new-volume install + headroom). Below that: STOP, report, external-SSD target is a coordinator decision — not auto-selected.
- Power gate: AC connected. Backup gate: Time Machine <7 days OR typed `OVERRIDE` (prior kit rule, retained).
- Installer acquisition from 10.13.6: `softwareupdate --fetch-full-installer` does **not** exist on High Sierra. Route = Apple's own catalog via `installinstallmacos.py` (Greg Neagle, Apache License 2.0 — pinned + hashed, see `PIN.md`) fetching `Install macOS Catalina.app` 10.15.7 directly from Apple CDN, then `codesign` / pkg signature + SHA-256 verification before any use. No third-party installer images.
- APFS prerequisite: 10.13.6 on this model must already be APFS (High Sierra converted SSDs automatically); preflight asserts the boot volume filesystem and stops if HFS+.

## Files
- `Upgrade-to-Catalina.command` — Mac-side one-click launcher, bash 3.2, dry-run first run, state file + resume, gates above.
- `distro-entry.json` — proposed Distro catalog entry (status `in-development`, no hash invented — filled at build verification).
- `COORDINATOR-BRIEF.md` — commsv2 brief for SH-3 Coding coordinator.

## Commercial position
Who pays: nobody — internal estate tooling for the owner's own machine. Who collects: nobody. Margin/commission: $0 / none. Apple installer is Apple's, free. Distro collects $0.

## Status
Scaffold-1 + coordinator tranche 2026-11-23 (see COORDINATOR-RESULT.md): launcher `bash -n` PASS post-repair; 32-bit inventory parser repaired and sample-tested; pinned-script staging fixed. **2026-11-23 13:02 EST update:** G-PIN opened by owner's approval — `installinstallmacos.py` copied into the package at commit `ae5d4a8a…`, SHA-256 `4b06e394…` recorded in `PIN.md`, launcher now enforces that hash at runtime; license attribution corrected (Apache-2.0 / Greg Neagle); the `--armed` gate bypass was removed — every invocation passes ARM + backup gates. NOT rig-run. S1 spec ✓ · S2 build OPEN (T1 pin DONE; T2 UNVERIFIED — no 10.13 host available on this side) · S3 served OPEN (not listed in Distro catalog; registry change drafted only, DISTRO-REGISTRY-CHANGE-DRAFT.md) · S4 rig OPEN (owner's Air, his verdict only).
Next: T2/S4 run on the Air at the owner's sitting.
