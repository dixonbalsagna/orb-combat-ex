# Selling your first game: a beginner's guide

Owner: Legal and IP Compliance. 2026-10-16. Written for Orb, who has not sold a game before. **General information, not legal or tax advice.** Where a professional is worth paying, it says so. Policies were read on 2026-10-16 and each fact says how sure I am. Marketing's plan (`docs/marketing/go-to-market-plan.md`) covers audience and numbers; `go-to-market.md` covers the legal details. This is the order of work.

## The honest starting point
A one-person game with no marketing budget usually earns little: most Steam games earn under a thousand dollars. That does not mean "do not sell". It means: sell on the cheapest, lowest-stakes shelf first, learn from real strangers, and spend money only as the numbers earn it.

## 1. Two shelves: itch.io and Steam

| | **itch.io** | **Steam** |
| :-- | :-- | :-- |
| Fee to start | None | **$100 per game**, paid by card; paid back to you once the game has earned $1,000 (Valve's own page) |
| The cut | **You choose it, 0 to 100%; the default is 10%.** Card fees come on top (about 2.9% plus 30 cents) (itch.io's own docs) | **30%** of sales until $10 million (a widely reported rate; check Valve's agreement) |
| Time to open a page | The same day | **At least 30 days from paying the fee to being allowed to release,** a public "Coming Soon" page for at least two weeks, then Valve's review of 1 to 5 days (Valve's page) |
| Browser game | **Yes, play in the browser** | No (a download) |
| How you get paid | You connect PayPal or Stripe and sales land there, **or** itch.io collects and pays you (7 days after a sale, then you request a payout; minimum $5; takes about 10 to 14 days). Choosing itch.io collecting makes **itch.io the seller** who handles VAT and chargebacks (their docs) | Valve pays by about the 30th of the month after the sales, if you are above a minimum (about $100, reported by third parties) |
| Tax forms | A tax interview before payouts (a US person: a W-9 style form) | A tax interview, a bank account **in the same name as your legal ID**, and an identity check |
| The audience | Smaller, loves experiments and free games | Huge, and crowded: about 20,000 games a year |
| The AI disclosure | A field you must answer | A survey section you must answer; it shows on your page |

**My recommendation:** start on **itch.io**, with the browser build free or "pay what you want". It costs nothing and you learn what strangers do. Go to Steam only when you have fighters worth a price and some followers.

## 2. The recommended order (the steps)
**Stage 0: before anything public.** Fix the flashing (the build must pass the release check on the exact version you publish). Decide the licence (see the rundown). Run the formal title search (the OrbCombat question). Decide whether to form a company before you take money (see the company guide).
**Stage 1: itch.io (free).** Create the account; write the page (title, a short pitch, screenshots, the AI statement, the flashing notice, the privacy line, the licence line); tick the AI field (graphics, sound, text and dialogue, code); upload the browser build; publish. Time: an afternoon. Cost: $0. No promotion yet beyond the page itself.
**Stage 2: learn.** Watch plays and comments for weeks. Fix what confuses people. No money has changed hands.
**Stage 3: your business setup, only when you will take money** (company or sole proprietor, bank account, a tax interview). See the company guide.
**Stage 4: Steam, when the numbers say so.** Pay the $100; the 30-day clock starts; build the Coming Soon page; add the trailer and screenshots; answer the content survey (AI, violence); set the price; submit for review; release. Plan about **two months** from fee to release.
**Stage 5: consoles (much later).** They need a legal entity, agreements and ratings, and the platform code stays out of the public repository.

## 3. A store page: what it needs
Title; a one-sentence pitch; a longer description; **the AI statement near the top** (Orb's rule: everywhere it is shown or sold); the **flashing notice**; screenshots from the real game; a short trailer; tags (genre words only, never another game's name); a price; the age and content answers; the privacy line; the licence line. **Never** write "human-made", "no AI", "safe for photosensitive players", a comparison to another game, or any claim about a feature that is not in the build. See `store-copy-screen.md` and `never-use-words.md`.

## 4. Age ratings
- **Steam** asks you to fill in its own content survey (violence, gore, sexual content, and so on); Valve uses it to rate your game (it matters, for example, in Germany).
- **IARC** is a free questionnaire used by Google Play, the Microsoft store, Nintendo and some others to hand out ESRB, PEGI and other ratings from one set of answers. Consoles use it or their own process.
- **itch.io** does not require a rating; it uses content tags and warnings.
- **Your game:** graphic violence is the working target, so expect the top of the scale (see `guide-stomp-and-ratings.md`). **Answer from the real build**, and do it before you open a store page, so nothing surprises you.

## 5. Tax basics for a US individual (Oregon)
- **You owe tax on what you earn from the game**, even a small amount. If you work for yourself you pay **self-employment tax of 15.3%** on net profit on top of income tax (IRS rules; I did not re-read them today).
- **Keep records from the first dollar:** every sale report, every cost (the Steam fee, subscriptions such as Suno, domain, software). Costs reduce your profit.
- **Quarterly estimates:** once you expect to owe a few hundred dollars, the IRS and Oregon expect payments during the year, not only in April.
- **Sales tax:** Oregon has none. Steam and itch.io's collecting mode handle sales tax and VAT for you. If you let itch.io pass sales straight to your own PayPal or Stripe, **you** become the seller and own VAT and chargebacks, so pick the collecting mode.
- **The tax interview** on Steam and itch.io asks for your name, address, tax ID and a form (a W-9 for a US person). Have your Social Security number or EIN ready; **never** type them anywhere except those official forms.
- **When to pay for help:** a CPA or an enrolled agent for one hour before your first sale, and again at tax time in the first year. It is usually worth it.

## 4b. The AI disclosure (Orb's rule), per shelf
Use the same words everywhere: `go-to-market.md` section 1 and `writing-note.md`. Steam's survey: pre-generated AI content yes; live-generated no (no AI model runs while you play). itch.io: tick graphics, text and dialogue, and code (and sound when the Suno music ships). Never call anything human-made unless the record shows it.

## 6. Costs you should expect (rough, first year)
Steam $100 (recouped at $1,000 of sales); itch.io $0; a company (optional) about $200 to $450 in Oregon the first year; an accountant about $200 to $500; Suno about $8 to $24 a month while you make music; a domain about $15 a year. You can start for $0.

## 7. Traps to avoid
Taking money before the flashing is fixed or the title is checked; putting your legal name where you want a pseudonym (the bank and the store need your legal name; the public page can say "Orb"); copying another game's words into your tags; promising features; buying or trading for reviews; a mailing list before you know how to run one.

## 8. Ask a professional
A lawyer (once, before the first sale): the licence files, the trademark search, the platform agreements' warranty about your music and art. An accountant: the business setup and the tax return. Neither is expensive for a project this size, and both are cheaper than a mistake.

## Sources (read 2026-10-16)
Valve's Steam Direct page (fee, tax, bank, waits; primary); itch.io's payments documentation (cut, payouts, merchant of record; primary); Valve's payment FAQ and press reports (the 30% rate and the payout date; secondary); IARC milestones (secondary); IRS general rules (not re-read today).
