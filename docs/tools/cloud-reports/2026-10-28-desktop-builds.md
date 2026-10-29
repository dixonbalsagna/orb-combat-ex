# Desktop test builds for Windows, Linux and macOS (Tools, 2026-10-28; re-cut for RL-203 to RL-205)

Brief: `docs/ep/cloud-briefs/tools-desktop-builds.md`, run locally (cloud sessions retired), then re-cut to Legal's RL-203, RL-204 and RL-205 (0ca0c6a9). Proofs ran on Orb's PC from a clean `git archive` of HEAD, headless, below-normal priority for the benches, one Godot at a time. Manual: `docs/tools/desktop-builds.md`. Nothing was dispatched.

## SUMMARY
- `desktop-builds.yml` (workflow_dispatch only) exports the three presets, plays the Linux binary against the project's gameplay hash, packs each platform as a folder (game, README.txt, NOTICES.txt, build_info.json), unpacks each archive again, checks it and uploads 3 artifacts for **1 day**. It **refuses to run** without `orbs_yes` (the date of Orb's yes, RL-203), unless the lock is true, the capture hook off, the route scan clean, the six bypass words as reviewed and no flag able to reach normal mode, no network class packed and `net/*` excluded from the three desktop presets.
- Local proof from clean HEAD: Windows exe 118.0 MB, Linux 82.2 MB, macOS zip 65.1 MB (universal Mach-O, two slices, ad-hoc signed); each package passes `verify --locked`; the routes check passes on the export tree; the Windows exe played headless prints `gameplay hash at tick 2400: d4f6342a1009bdbc`, equal to the project's. The Linux binary and the macOS app were not run here (a Windows PC cannot); Windows and macOS are read, not run.
- Negative proof on a real export: a Linux export with `net/*` taken out of its exclude filter fails `verify` ("carries scripts from res://net/").
- Self-test 124 checks (was 71); check-workflows ok.

## CHANGES (this re-cut, on top of the first park)
- README.txt: the Windows antivirus sentence replaced by Legal's three sentences, "from this app only" lead-in on the `xattr` step, LICENSES / "license", Legal's PRIVACY section after HOW THIS GAME WAS MADE, word for word. Constants in `desktop-package.mjs` are held against Legal's addendum by the self-test.
- Package check: Legal's words, none of safe / tested / verified / virus-free / compliant (README and our own text in NOTICES.txt; the license texts stay as published: the MPL contains "compliant"), no `res://net/` in the packed file list, `capture_hook` off.
- New `routes` command, run by the workflow after the lock edit: items above. Workflow: `orbs_yes` input and first step, no lock input (always locked), `retention-days: 1`.
- Outside my paths, parked as `export-presets-macos.patch`: the macOS preset (app name "Orb Combat EX", placeholder bundle id: RL-205) **and `net/*` in the exclude filter of the Windows, Linux and macOS presets** (not Web, so RL-197's flash-set rule is unchanged). **The routes check, and so every run, fails until this is applied.**

## DECISIONS
- "The six route words" = the six `BYPASS_WORDS` (bench, frames, shot, nonotice, flashcap, study). On a desktop they are honoured by design (a bench, a scripted shot). The check proves none of them, and no other argument, writes the lock, the option, the register or the F8 key, and that the capture hook cannot attach off the web. It is a **static** check of the commit's sources, not a run of the exported game with flags.
- Online play unreachable = no production reference to any network or `Net*` class, `net/` out of the pck (proved on a real export), no autoload of it. I did not find any connection made by the game: no HTTP, ENet, UDP, TCP, WebSocket or WebRTC class is packed.
- `project.godot` stays untouched (ETC2/ASTC import is set on the CI checkout only).

## NEEDS FROM EP
1. Land `export-presets-macos.patch` first (the routes check needs the `net/*` exclusion and the macOS preset), then `desktop-builds.patch`. Do not dispatch before Orb's yes.
2. RL-203 conditions 2 (the commit passes a pin move's bar: nightly, signature and collapse reduced within 2.5 / 3 / 2) and 4 to 6 are not enforced by the workflow; they are yours. The signature reading on record for the live pin 257a766c is over the limit (grandfathered, RL-202), so a build of that commit does not meet condition 2 as written: Legal should say whether it counts.
3. On a desktop the six words skip the flashing notice when named on the command line (`UiHud.bypass_allowed()` is true off the web). They do not lift the lock. If Legal wants them refused in a locked desktop build, that is a one-line change in UI's `ui_hud.gd` (outside my paths).
4. Windows and macOS builds have not been opened by anyone: a Windows PC and a Mac that did not build them are needed.

## RISKS
- First run unproven on GitHub: the template paths in the .tpz, `zip` on the runner image (not installed here, so its two lines have run nowhere; the tar round trip did).
- The `routes` check is static. A new way in is a new rule (as for the site's route scan).
- macOS goes through Apple's deprecated OpenGL; nobody has seen it draw.
- Artifacts are zips of zips; a tester unzips twice.

## NEXT
Idle until Orb's yes and the EP's landing; I fix what the first run finds.

## Gates run
check-workflows ok, self-test 17; desktop-package self-test 124; `routes` on the export tree ok; `validate` and its self-test and lint ran green on the first cut and nothing they read has changed.
