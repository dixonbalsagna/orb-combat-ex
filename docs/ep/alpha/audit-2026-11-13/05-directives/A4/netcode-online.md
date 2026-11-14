# A4: Netcode & Online

Leads: A-NET-06
Supports: A-MODES-09, A-WORLD-02, A-AI-08

Goal: Orb and the trusted second player finish five full LAN 2v2 matches in each of the two forms (as a team together, and apart) on two real PCs without the two PCs ever falling out of step, and there is a saved record that says so.

Context:
- Read first: `docs/ep/alpha/audit-2026-11-13/04-path-to-alpha.md` (section A4; X-08 under "Exit criteria this audit proposes to change"; decision 13); `docs/ep/alpha/audit-2026-11-13/02-areas/NET.md` (F-NET-09; line 68, the X-08 row); `net/lan.gd` (the two 2v2 setups at lines 32-35; the flags at lines 117 and 129-130); `net/tools/lan_words.txt`; `net/tools/lan_kit.mjs`; `net/desync.gd`; `docs/net/runs/6a30b4c9/lan-folder/lan-loop-rows.txt`; `docs/rendering/2v2-drawn-plan.md` (the row for Netcode and Tools).
- A-NET-06 (S, minor): LAN 2v2 has been played on two real PCs only in its team form and only on the 2026-11-07 build; the apart form has no real two-PC record on any build. Evidence: `docs/ep/vision.md:1662`; the LAN log kept from the 2026-11-07 build's second PC; `docs/net/runs/6a30b4c9/lan-folder/lan-loop-rows.txt` (rows with the second PC simulated inside one program).
- Supporting rows: A-MODES-09 (seeing all four fighters: the 2v2 launchers do not pass the word that draws the other fight, `net/tools/lan_kit.mjs:143-158`); A-WORLD-02 (the planet's seed and three dials must be agreed by both PCs before tick 0; today `net/lan.gd` fixes `"planet": 7` in its setups); A-AI-08 (a LAN line-up with a computer partner, if the line-ups page names one; today `AI2` at `net/lan.gd:35` puts both computers on the enemy side).

You own: `net/`, `docs/net/`.
- No grant is expected for the lead row. The in-game Host and Join row (A3) is where the 2v2 forms are started; menu rows are UI's.
- ask under NEEDS FROM EP for a grant: `tools/schemas/` (only if the handshake's data shape is described there and changes)

Acceptance criteria:
1. (A-NET-06, X-08) On the A4 build, two real PCs play five full matches of 2v2 together and five full matches of 2v2 apart. For every match the LAN log's state checks all match and no "OUT OF STEP" line appears. Both PCs' logs and report folders are saved under `docs/net/runs/<sha>/`, with one summary row per match (form, length in ticks, checks matched). The play is Orb's and the trusted second player's; your part is the one-page instruction, the build's LAN folder, and reading the returned logs.
2. (A-NET-06) The one-page instruction says in plain words what each person presses on each PC for each form, and how to get the report folder back to the EP. It uses the in-game Host and Join row from A3, with no address written into files.
3. (A-NET-06) If any match falls out of step, the first differing tick and field are named from the logs and the finding goes to the EP as a bug with its severity; the criterion stays open until five clean matches in a row per form are on record.
4. (support, A-MODES-09) Once Rendering's "others near" work is on main and the EP says the kit may carry it, the 2v2 together start passes the word that draws the other fight's bodies; the effects word is passed only after the per-screen switch and its safety clips pass. The two-program check in CI still passes with the word on.
5. (support, A-WORLD-02) Both PCs name the same seed and the same three dials before tick 0; a joiner whose choices differ is refused with a plain notice. A check in CI (an extension of `net/tools/lan_check.gd`) covers a matching and a mismatching pair.
6. (support, A-AI-08) If the line-ups page names a LAN line-up with a computer partner, its setup is added beside the existing two and covered by the same check; if not, say so in one line.
7. Evidence: CI results and the two-PC records are saved under `docs/net/runs/<sha>/`.

Constraints:
- Tokens: about 0.25M as an estimate (S): play time and log reading. The supporting work is counted under its lead rows.
- The lead row does not change the sim's state hash. The supporting handshake change carries Simulation's key and is tied to golden window GW3, "Many bodies and the full fighter": it lands with the dials, not before.
- Machine: the real-socket check (`net/tools/enet_check.gd`) runs in CI only and never on Orb's PC (a socket there can raise a firewall prompt, and no prompt may be put in front of Orb); Godot headless only for local checks, at most 3 processes for a short gate; long runs at below-normal priority.
- Determinism: seeded RNG, fixed step; both PCs read the same setup and the match key holds every setup key; no rendering state in the sim.
- Originality: nothing here touches content.
- Orb's rules: LAN at Alpha is for Orb and the trusted second player on two Windows PCs (the outside testers' package has no LAN row, if Orb accepts decision 13); nothing is sent anywhere automatically; plain words in every notice and in the instruction page (Orb sees forward-facing text before use); no network address, name or place of anyone in any file or report.

Return: the standard report format (SUMMARY, CHANGES, DECISIONS, NEEDS FROM EP, RISKS, NEXT).

Order: Before this starts: LAN inside the game behind the Host and Join row, and a two-PC record on the played build (A-NET-01, A-NET-02, A3). The five-match sessions wait for the A4 build with the GW3 rows landed, so the record is on the rules that ship. Waiting on this: X-08's must-pass line for LAN 2v2, and the mode smoke suite's LAN 2v2 run on Windows.
