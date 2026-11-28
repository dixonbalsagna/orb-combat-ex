# The Linux first-start kit (gate G23)

Owner: Tools. Built 2026-11-28; **not yet tried on a real Linux machine**, and its words need Legal's read before it goes to anyone.

## What it does

One script for the first person to start the Linux build (RL-280): it **checks the game's file** against the checksum of the build Orb made, **runs the game's own test with no window** and compares the result with the build's, then **opens the game to its flashing warning and closes it by itself** after 20 seconds, and asks whether the warning appeared. No match is started. It writes one line for the person to send back.

It sends nothing, deletes nothing, and records no name, computer name, system name or folder path.

**Optional since 2026-11-28:** the USB-stick route (`linux-usb-kit.md`) runs this same script as its first part and covers G23, so no friend is needed for it.

## Who runs it

The trusted friend (RL-280), **or Orb or Orb 2 from a Linux USB stick** on their own PC: RL-300 says that meets G23 too, so the friend need not go first.

## Make it

After a build with a Linux package (`node tools/desktop-local-build.mjs --platform linux --audience testers`, or the owner build):

    node tools/first-run/linux-first-start.mjs --record <out folder>/build-record.txt --out <out folder>

This writes `FIRST-START.sh` with that archive's name, checksum and expected result filled in. A kit from one build refuses another build's file.

## What the person does

1. Put the game's `.tar.gz` and `FIRST-START.sh` in one folder.
2. Open a terminal in that folder and run `sh FIRST-START.sh`. (It is one command, not a double click: Linux desktops differ too much to promise that.)
3. When the game opens, **press nothing**. It closes by itself.
4. Send Orb the one line it prints.

## What the line looks like

    G23 first start | archive sha256 <64 characters> | bench <result> (same) | warning appeared: yes | closed at the warning: yes, by this script | a Linux x86_64 desktop

That is the record G23 asks for (the archive's checksum, the headless result equal to the build record's, the warning appeared, closed at the warning). `DIFFERENT` after the result, or `no` after the warning, is a finding: stop and look.

## Open, for the EP and Legal

- **How it reaches the person.** The build has one route (the restricted page). The kit is made after the archive and holds its checksum, so it cannot sit inside it: it would be a second file on the same page. Legal's to rule.
- **The script's words** are Tools' drafts.
- It is **not** gate G21 (a flash reading of the Linux program): nobody plays until that exists.

## Checks

`node tools/first-run/linux-first-start-selftest.mjs` (CI): reads a build record, and runs the script with a stand-in program in a real archive (right file, wrong file, different result, no desktop, missing file).
