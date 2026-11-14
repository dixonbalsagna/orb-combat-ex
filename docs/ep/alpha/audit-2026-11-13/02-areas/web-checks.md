# Web checks: platform rules (judgment session)

Read on 2026-11-13 by the judgment session, with web search limited to each platform's own domain. **How far to trust these:** each line is what the search returned from the page named; the pages themselves were not opened in a browser (the audit runs none). Where two of a platform's own pages disagree, both are given. Before anything is spent or published on the strength of a line here, the person doing it reads the live page.

Cite a row in the register as `url:<address> (read 2026-11-13)`.

## itch.io (Alpha distribution; criteria X-30, X-31)

| Rule | What the platform's page says | Page |
| --- | --- | --- |
| Restricted pages | A restricted project is open only to people the creator approves. It doesn't appear in itch.io's browse pages, search or profile pages, and isn't indexed by outside search engines. | https://itch.io/docs/creators/access-control |
| Download keys | The creator generates a special address that gives one person full download access. Keys can be named, their use counted, and revoked; revoking removes that person's access. | https://itch.io/docs/creators/access-control |
| A key and an account | Support threads say claiming a key needs an itch.io account, and one reports keys leading to a "not found" page until the key's "can be claimed" option was on. These are forum threads, not documentation: **to confirm in the rehearsal (X-31).** | https://itch.io/t/4552485/restricted-access-not-working-and-download-keys-require-account |
| Draft is not for sharing | A support thread says draft mode isn't designed for distributing a game to other people. | https://itch.io/t/296004/created-game-status-is-restricted-generated-link-has-nothing-to-download-yet |
| The upload tool, channels | `butler push <folder or zip> user/game:channel`. A channel name containing `win` or `windows`, `linux`, `mac` or `osx` tags the upload for that platform. Lower-case, dash-separated names are recommended. | https://itch.io/docs/butler/pushing.html |
| Versions | Each channel gets a rising integer version by default; `--userversion` sets our own. Order is upload order, not the version string. | https://itch.io/docs/butler/pushing.html |
| Rolling back | A forum answer says butler keeps a history per channel and users of the itch app can select a previous version. The manual line for this was not returned by the search: **to confirm in the rehearsal (X-30).** A fallback that needs no feature: push the previous build again as a new version. | https://itch.io/t/1644418/how-to-handle-different-channels-per-version |

**For the plan:** two channels, `windows` and `linux`; our own version string on every push; the rollback step is rehearsed with a dummy build before a tester ever depends on it. Creating the account and page, generating keys and installing the upload tool are Orb's actions.

## Discord (tester reports; criterion X-21)

| Rule | What the platform's page says | Page |
| --- | --- | --- |
| Free upload limit | The File Attachments FAQ gives **20 MB** for free accounts, raised from 10 MB in August 2026; the developer documentation gives 20 MiB as the default for all users. | https://support.discord.com/hc/en-us/articles/25444343291031-File-Attachments-FAQ |
| Older pages disagree | Some of Discord's own help pages still show 10 MB (the image upload guide, the account caps table). | https://support.discord.com/hc/en-us/articles/33694251638295-Discord-Account-Caps-Server-Caps-and-More |
| Paid tiers | Nitro Basic 50 MB; Nitro up to 1 GB. | https://support.discord.com/hc/en-us/articles/115000435108-What-are-Nitro-Nitro-Basic |

**For the plan:** cap the report file at **under 10 MB**, the lower of Discord's two published figures, with clips separate or optional. A cap of 10 MB holds whichever page is right.

## Steam Deck (criteria X-22, X-24)

| Rule | What the platform's page says | Page |
| --- | --- | --- |
| Smallest text | Interface text must be readable from 30 cm; the smallest character should never be under **9 pixels** high at 1280 by 800. Valve recommends aiming for **12 pixels**. | https://partner.steamgames.com/doc/steamhardware/compat |
| What failing costs | Most failures in this category give a "Playable" badge, not a block. | https://partner.steamgames.com/doc/steamhardware/compat |
| Resolution | 1280 by 800 preferred, or 1280 by 720. | https://partner.steamgames.com/doc/steamhardware/compat |
| Text size setting | Valve recommends letting users adjust text size. | https://partner.steamgames.com/doc/steamhardware/compat |

**For the plan:** the specification's proposed 9 px is Valve's bare minimum. The audit's proposed number for X-22 is **9 px as the floor that fails the sweep, 12 px as the aim**. The compatibility review itself belongs to a Steam release (Beta), not to an itch.io Alpha. How Valve schedules that review was not returned by the search: not evidenced.

## Steam (the demo at Beta; section 10.5)

| Rule | What the platform's page says | Page |
| --- | --- | --- |
| The fee | $100 per app. Not refundable; recouped only after the app reaches $1,000 in adjusted gross revenue. **A free game never reaches that, so the $100 is spent.** | https://partner.steamgames.com/doc/gettingstarted/appfee |
| Waiting period after paying | **Valve's own pages disagree:** the onboarding documentation as returned today says 30 days between paying the fee and releasing; the older Partner Program page says 21. Plan on **30**, as the project's notes already do. | https://partner.steamgames.com/doc/gettingstarted/onboarding and https://partner.steamgames.com/steamdirect |
| Paperwork | The older Partner Program page puts identity, tax and bank paperwork at 15 to 30 days. Old page; treat as "weeks". | https://partner.steamgames.com/steamdirect |
| Store page review | Usually 3 to 5 business days; Valve asks for the request at least 7 business days before the page should be live. | https://partner.steamgames.com/doc/store/review_process |
| Build review | Usually 3 to 5 business days; plan for at least 7. The store page must be submitted for review before the build can be. | https://partner.steamgames.com/doc/store/review_process |
| Coming soon | The page must be public as "coming soon" for at least two weeks before release. | https://partner.steamgames.com/doc/store/releasing |
| A demo | A demo is its own app id, created from and linked to the base game's app. It can have its own store page (which then needs a trailer and at least five demo screenshots) or only a button on the base game's page. The base game's page is re-published after the demo is released for the button to appear. | https://partner.steamgames.com/doc/store/application/demos |
| Steam Playtest | A child app with no store page of its own; it shows as a section on the base game's page (so it still needs the base app, the fee and a public page). Page is old. | https://partner.steamgames.com/doc/features/playtest |
| Content survey and AI | The survey is completed before a store page or build is submitted. AI-made content that ships with the game is "pre-generated" and is reviewed like any other content; content made by AI while the game runs is "live-generated" and needs a description of its guardrails. | https://partner.steamgames.com/doc/gettingstarted/contentsurvey |
| Next Fest, February 2027 | Registration closes 10 January 2027, 11:59 pm Pacific. Needs a published, public store page and a playable demo by the start (22 February). A game may appear in one Next Fest only; the next edition is planned for June 2027. | https://partner.steamgames.com/doc/marketing/upcoming_events/nextfest/feb_2027 |

**For the plan:** the stand-in's draft timeline (the specification's section 10.5) holds against these pages. Two notes for it: (1) the game's procedural content is generated by the game's own code, not by an AI model at run time, so on the survey it is pre-generated AI-assisted content; Legal confirms the wording. (2) February 2027's Next Fest needs a public store page by 10 January, which needs the title cleared, the fee paid and the page reviewed in under two months from now with no Alpha yet: it does not fit. June 2027 is the first edition worth weighing, and only once Beta is in sight.

## Not checked

- Windows' warning on unsigned programs and the price of code signing (PERF area): no platform page read yet.
- itch.io's own app on the Steam Deck in desktop mode, and adding a non-Steam game to the Deck's library: no platform page read yet.
- Whether the two-week "coming soon" rule and the 30-day wait can run at the same time.
