# Changelog (A-TOOLS-07)

One entry for every build handed to a person (a kept build, a desktop build, a test build), newest on top. `node tools/version.mjs --next` adds the entry and raises the build counter in `tools/version.json` together, in the commit that is built. Each entry has two parts: **For players** in plain words, which Orb reads before it is used anywhere (no team nicknames, what a player presses and sees), and **For the team**, the commit subjects since the last entry. Build 0 means no build has been numbered yet.

