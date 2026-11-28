# Checking the Linux version from a USB stick, on the older PC

Owner: Tools. Written 2026-11-28. **Not ready to use yet:** it needs the testers' package (which cannot be built until the borrowed shader code with unknown terms is replaced), and none of it has been tried on a real Linux computer. The EP decides when to ask Orb.

## What this is for

Before anyone plays the Linux version (friends on Linux or a Steam Deck), two things must happen:

1. **A first start:** a person opens it, sees the flashing warning, and closes it.
2. **A check of its picture:** the game records its own frames, and the team's tool reads them for flashing.

A USB stick lets the older PC run Linux **without installing anything**. Windows on it stays as it is. Doing this yourself, or having Orb 2 do it, covers both, and no friend has to go first.

## What you need

- The older PC, with its screen, plugged into the internet (cable or Wi-Fi).
- **A USB stick of 8 GB or more** to become the Linux stick. **Everything on it is erased.**
- **A second USB stick or drive with about 10 GB free,** for the game and the recording.
- Time: allow an evening. How long the recording takes is not known yet.

**Before you start:** if Windows on that PC is encrypted (BitLocker, or "device encryption"), have its recovery key to hand. Do not change any settings in the PC's start-up (BIOS) screens.

## 1. Make the Linux stick (on your main PC)

1. Download **Ubuntu Desktop 24.04** from `https://releases.ubuntu.com/24.04/`: the file `ubuntu-24.04.5.1-desktop-amd64.iso` (about 5.8 GB). It is the same Linux the team's online build machine uses.
2. Check the download. In PowerShell, in the folder it landed in:

```powershell
(Get-FileHash .\ubuntu-24.04.5.1-desktop-amd64.iso -Algorithm SHA256).Hash.ToLower()
```

   It must print `4da4a0c9035da8e68a59a838674f403f0a54472c78a83b4fb7f78d03588f85a7`.
3. Write it to the first stick with **balenaEtcher** (Ubuntu's own instructions recommend it): choose the file, choose the stick, press Flash. Check twice that it is the right stick.

## 2. Put the game on the second drive (the team does this)

A session writes three files onto it: the game's package, `FIRST-START.sh` and `RUN-READING.sh`.

## 3. Start the older PC from the stick

1. **Screen cable:** if the motherboard has its own video socket (beside the USB sockets), use it: Linux supports that built-in graphics better. If not, the graphics card is fine; if the screen then stays black, pick "safe graphics" in the first menu.
2. Plug in the Linux stick, switch on, and tap the **boot menu** key straight away (often F12, F11 or F8). Choose the USB stick.
3. When Ubuntu asks, choose **Try Ubuntu**. **Never "Install".**
4. Connect to the internet (top right corner), then plug in the second drive.

## 4. The one command

Open the second drive's folder, right-click an empty space, choose **Open in Terminal**, and type:

```
sh RUN-READING.sh
```

- **Part 1:** press Enter when it asks. The game opens at its flashing warning. **Press nothing** (no keys, no mouse button, no controller). It closes itself after 20 seconds. Answer whether the warning appeared.
- **Part 2:** it fetches one small program (a hidden screen, held in memory only), then the game plays by itself **where nobody can see it** and writes every frame to the second drive. Text scrolls; wait for "Done".

Then shut down, take both sticks out, and the PC starts Windows as before. Bring the second drive to your main PC.

## What is read and what is kept

| What | Where it goes |
|---|---|
| The game file's checksum, its own test result, whether the warning appeared | one line in `first-start-result.txt` on the second drive |
| The frames of the recorded match | the second drive, then your main PC only. **Never into the project, never online** |
| How many frames, and the name of the graphics drawing them | `reading/record.txt` |
| The team's reading of the frames (numbers) | the project, with "a Linux live system" as the setup |

No name, computer name or folder path is recorded, and nothing is sent anywhere by these scripts. You can erase the recording once the team has read it.

## What it does not show

- The recording is drawn by software on the hidden screen, not by the older PC's graphics hardware.
- It is not a Steam Deck check.
- A picture check goes with it (the same scenes beside the Windows or browser version; a missing building or effect voids the reading). **How that is done is not designed yet.**
- Which matches must be recorded is decided after the first trial. The script records one for now.

## For sessions

```
node tools/first-run/linux-usb-kit.mjs --record <testers build record> --archive <that Linux .tar.gz> --out <folder on the second drive>
node tools/flash/analyse-frames.js <drive>/reading/seed-12345/frames --scale 1
```

The kit refuses a package that is not the record's. The lock check for that same checksum is in the build record. The script's steps are tried on real Linux by `.github/workflows/linux-reading.yml` (by hand; nothing kept) and with a stand-in by `node tools/first-run/linux-usb-kit-selftest.mjs` (CI). More seeds: `ORB_READING_SEEDS="1 2 3" sh RUN-READING.sh`. Rulings: RL-298 to RL-301; background: `linux-reading-options.md`.
