# Getting a reading from the Linux build: options (Tools, 2026-11-28; a study, nothing installed)

## Two different things are owed

| Gate | What it needs | Who |
|---|---|---|
| **G23** | A person starts the testers' Linux program on a Linux machine: the headless bench line, then open it, see the flashing notice, close. **Nothing flashing is shown** | One trusted friend (RL-280) |
| **G21, Linux half** | A **flash reading of the actual Linux program** friends get: the same commit and package, Reduce flashing locked on, taken from its own frames, named by file and checksum | Tools, before any Linux or Deck friend plays a match |

A first start does not satisfy G21, and the friend cannot supply G21 by playing: nobody plays until it is read.

**How a reading would be taken, in every option.** The package cannot pose test scenes (by design), but it can play its own computer match, and the engine can write every frame at a fixed rate (`--write-movie`, documented as available in release builds). A slow or software renderer then gives the same frames as a fast one, and Tools' analyser reads the frame files. It reads real play, not the worst-case scenes. **None of this has been tried with our package:** whether it records, whether the computer match draws in a window that way, and whether the analyser reads the output.

## What is on Orb's PC today (read only)

Windows 11 Pro, 31 GB of memory, over 1 TB free, two graphics devices (an NVIDIA card and the processor's own). Virtualisation is on and Windows' hypervisor is already running. **The Windows Subsystem for Linux (WSL) is not installed** and no Linux system is registered.

## Option 1: WSL2 on Orb's PC

- **Installs and changes.** Orb runs `wsl --install` as administrator and restarts: it turns on the Windows features it needs, installs WSL and an Ubuntu system (a download of roughly 1 GB, a few GB of disk), and Orb makes a Linux user name and password. Tools would then add the few Linux packages for a hidden display. While it runs, the Linux system can take a large share of memory. It can be removed again (`wsl --unregister`, then uninstall).
- **Cost.** No money. About half an hour of Orb's time including the restart; about a day of Tools' work to build and prove the capture.
- **Risk.** Low to moderate: a restart and a new system component on Orb's own PC; other virtual-machine programs can be affected, less likely here because the hypervisor is already on. The password is Orb's to type; no session sees it.
- **What it reads.** The very testers' file, which exists only on this PC. A real Linux program, but under WSL's display and graphics layer, not a Linux desktop's drivers and not a Steam Deck's. A graphics card is not needed for a reading.
- **Would it count for G21?** **Not known: Legal must rule.** RL-280 names WSL as worth trying and says whether its reading stands is ruled once the method is shown.

## Option 2: a CI runner with software rendering

- **Installs and changes.** Nothing on any of our PCs. A new hand-started workflow: build the Linux program from the commit, play the computer match under a hidden display, analyse, keep the numbers only.
- **Cost.** No money (public repository). Under an hour of runner time a run; about half a day of Tools' work.
- **Risk.** Low for people. Two technical ones: software rendering may draw the game wrongly (the browser's software renderer drew no buildings until Rendering fixed it), so a reading needs a picture check beside it; and **anything a public repository's run keeps can be downloaded by others**, so no frames or clips would be kept.
- **Would it count for G21?** **Not as the gate is written.** The testers' package is made on Orb's PC and must not be uploaded, so a runner can only read its own build of the same commit: a different file, with a different checksum. It would count only if Legal accepted that, or if the two builds' contents were proven the same (not yet looked at).
- **Worth doing anyway:** it is the free way to find out whether the method works at all.

## Option 3: a one-click kit for the trusted friend

- **What it is.** A script that goes with the testers' Linux package: it checks the file's checksum, runs the headless bench and shows its one line, then opens the game and says in large words to close it at the notice. It sends nothing by itself and records no name, system or path.
- **Installs and changes.** Nothing on Orb's PC. Nothing installed on the friend's.
- **Cost.** No money; about half a day of Tools' work; a few minutes of the friend's time.
- **Risk.** The friend's system is unusual, so a failure may be that system's own (RL-280). The kit must reach the friend only the way the package does.
- **Counts for:** **G23 only.** It cannot give G21: a reading made on the friend's machine would either show them the unread match, or need extra software installed there and gigabytes of frames sent back. I do not recommend either.

## Also possible, not asked for: a Linux USB stick on the older PC

Start a PC from a Linux "live" USB stick without installing: a real Linux desktop with real graphics drivers, and the disk is left alone. It needs a spare stick, a download of a few GB, and Orb choosing "try", never "install", at the boot screen. No money if a stick is spare. It is the nearest we can get to a player's Linux machine without anyone else's. Whether it counts, and whether Orb may do G23 on it instead of the friend, are Legal's to rule.

## Recommendation

1. **Ask Legal first**, which costs nothing: would a G21 reading count (a) under WSL, (b) on a runner's own build of the same commit, (c) on a live USB stick?
2. **Prove the method on a runner** (option 2). No installs. If the package will not record or draws wrongly, we learn that before asking Orb for anything.
3. **Then ask Orb for one install** only if Legal accepts it: WSL (option 1) if it counts, else the USB stick.
4. **Build the friend's kit** (option 3) in parallel for G23, which does not wait on any of this.

If none of these is accepted for G21, matches on Linux and Deck wait; Windows keys are not held by it (RL-280).
