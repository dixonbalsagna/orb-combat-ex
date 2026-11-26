# The report server: what to set and check (for Orb's step page)

Legal, 2026-11-25. A screen, not legal advice. For the private Discord server where testers post report files (gate G15). Discord moves its menus around, so a setting may sit under a slightly different name.

## Set these (about 20 minutes)

1. **A new server.** Don't reuse one that has people or history. Call it "Orb Combat EX testers (working title)". No character art for the icon or anywhere else.
2. **Your own account:** no real name or photo, and two-step sign-in turned on. Your friends will see this account.
3. **Keep it unlisted:** don't turn on "Community" (that is what lets a server be found), keep the server widget off, and never post a link anywhere.
4. **Members can't invite:** in Roles, @everyone, turn off "Create Invite". Also off: mentioning @everyone, creating threads, and every "Manage" permission.
5. **One channel.** Delete the others, voice channels too. Friends can read it, post in it and attach files. They will see each other's names and reports.
6. **Nothing automatic:** no bots, no webhooks, no connected apps. The game never posts there by itself.
7. **Safety Setup:** require a verified email to post.
8. **One invite per friend,** set to one use and a short expiry. When everyone has joined, delete any leftover links and pause invites.
9. **Pin this as the first message:** "Adults only. This is private: don't share, screenshot or forward anything from here or from the game. Don't post real names or other personal details, yours or anyone else's. Glance at a file before you attach it."
10. **Each friend replies there:** "I have read the note and the README, I am an adult." Keep your own dated list of who did, on your PC, outside the project (gate G16).

**Files you download from the channel** go only into `.private\testers\` inside the project (that folder is never uploaded). Put your friends' names and account names in `.private\testers\names.txt`, one to a line: the project's checker then fails if a name slips into any project file. Without that file, names are not checked.

**The line the game's package needs:** put one line in `.private\testers\report-channel.txt` that describes the channel in plain words, for example `the private test channel you were invited to with your key`. No link, address, handle or name. A package for friends cannot be made without it.

## The question: may we promise a friend that their reports are deleted if they ask?

**Legal's recommendation: yes.** It costs a few minutes, and in some countries a person can ask for this anyway.

**If yes, the words the friend gets are:**
> If you ask, Orb will delete your report files and messages from the report server, and Orb's own copies, within 14 days. Reports are read with the help of AI services run by another company. Discord and those services may keep copies under their own rules, and Orb cannot remove what someone else has already saved.

**And you do this when asked:**
- Search the server for their name and delete each of their messages and files. Do it before or after they leave: leaving doesn't remove them.
- Delete their files from `.private\testers\`, your Downloads folder and the Recycle Bin, and anywhere else you saved a copy.
- Remove them from your list and from `names.txt`.
- Add nothing that makes extra copies of messages (a logging bot, an auto-backup).

**If no:** the sentence "If you want your reports deleted, tell Orb and they will remove them" comes out of the tester note before anyone gets it. If someone asks anyway, delete what you can.

## When testing ends

Delete the server, and the files in `.private\testers\` once the faults they show are fixed. Tell Legal first if the server is ever to open to more people, take automatic uploads or be used for anything but reports.
