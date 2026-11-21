# A-TOOLS-13 on the owner-private route: the Windows build made and started on a Windows runner (Tools, parked 2026-11-21; the EP's decision)

The two Windows jobs of `desktop-builds.yml` (`windows-bench`, `windows-still`) need the Windows zip the first job packs, and only an **outside-testers** run uploads it, so on the owner-private route they never run and the row has never been proven. The EP's decision: **export on the Windows runner itself** for the owner-private route, so no artifact crosses and no new Legal question arises; the two existing jobs stay as they are for outside-testers (they test the very zip that ships).

`windows-local.patch` (sha1 `0ef9a70fb7e9c91cbb38e1bf6cc3f16453c64f10`, applies to HEAD, two files):

| File | Change |
| :--- | :--- |
| `.github/workflows/desktop-builds.yml` | a new job `windows-local`, `if: inputs.audience == 'owner-private'`, `needs: desktop`, `runs-on: windows-2025`. It checks out the commit the first job built, installs Godot 4.7.2's **Windows** editor and the **Windows release template** (each SHA-512 checked against the release's `SHA512-SUMS.txt`; the template's pin is the one `setup-godot` already holds), prepares the checkout as the first job does (lock, version fields, ASTC), imports, writes `build_info.json`, **exports the Windows exe on the Windows runner**, plays the same bench match through the console wrapper of the same export and compares its gameplay hash with the first job's Linux hash (a job output, text), then starts the **windowed** exe on the runner's desktop through ANGLE and measures one still of the screen |
| `docs/tools/desktop-builds.md` | one bullet in "The Windows jobs" describing it |

I did **not** drop the `if:` of the two existing jobs: dropping it would make them try to download an artifact an owner-private run never uploads, and they would fail. A separate job says it plainly instead (the outcome the EP asked for: the Windows start proof runs on owner-private too).

## What is not kept, on purpose

**The still is not saved.** A kept file is an upload (RL-262: an owner-private run keeps nothing), and `tools/check-desktop-audience.mjs` fails on an upload step that is not gated to outside-testers. The summary carries the evidence in text: whether the game was still running after 30 s, the screen size, the number of distinct colours in a sample (a flat screen fails the job), and the game's first lines. **A picture of the Windows build therefore comes only from an outside-testers run, or from Orb starting it once** (the path-to-alpha's own rule): say if you want the owner-private route to keep the image for a day instead; that is Legal's word on an in-run artifact, the question this design avoids.

## Proof, and what is not proven

- `check-workflows` ok (13 files), `check-workflow-shell` ok (266 run steps parse, 8 more than before), `check-desktop-audience` ok (every upload and download is gated; the new job has none) and its self-test 12 checks, 0 failed; the PowerShell step parses with PowerShell's own parser (no errors).
- **Never run on a runner.** Nothing here has started on a hosted Windows machine. What the first dispatch will show, and what I expect to iterate on: (1) the still step, since a hosted runner has no GPU, WARP is untested here and `CopyFromScreen` may need an interactive session; (2) the bench through `orb-combat-ex.console.exe` (a console wrapper of the same export, not the windowed exe, so the printed hash is the same engine and pck); (3) the template extraction with `7z` (names `templates/windows_release_x86_64.exe` and `version.txt`, as the Linux job extracts them); (4) the run's time against the job's 60-minute limit (the 1.28 GB templates download dominates; an estimate, not a measure).
- Closing evidence for A-TOOLS-13, after GW1a lands: one owner-private dispatch with the job green, its summary (bench hashes equal; the game up after 30 s) saved under `docs/tools/runs/<sha>/`. Until then Production's row reads "written, not run".
