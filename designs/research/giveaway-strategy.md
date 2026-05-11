# Giveaway strategy

How many keys can the studio give away across all avenues before taking real loss? The framing: at a certain volume, giveaways are not costs because the recipients would not have bought the game anyway (digital keys are zero marginal cost; forgone-sale only counts if the person was a real buyer otherwise). The doc puts a defensible ceiling on that argument.

This document is the team's opening position. The numbers are derived from the published indie record, not from Volley's own data. They will firm up against real sales once the project has its own measurements; until then, treat the caps as conservative working bounds.

## Headline

Across the open empirical record, the studio can defensibly distribute roughly **3 to 6 percent of expected paid units as free keys per band** before the math tips from "wouldn't have bought anyway" into real revenue loss. For Volley specifically, that puts the **Band 0 to 1 ceiling around 750 to 1,500 keys total across all channels**, climbing roughly with sales volume. The constraint at low bands is not cannibalisation but key-resale exposure and chargeback risk; at higher bands the constraint flips toward dilution.

## Cannibalisation: how many recipients would have bought anyway

Direct studies of giveaway-key cannibalisation are thin. The closest analogue is the piracy-displacement literature, which is the steel-man for "they wouldn't have bought anyway." The EU's 2017 commissioned study found "no robust statistical evidence of displacement of sales by online copyright infringements" across most game categories ([summary via ResetEra](https://www.resetera.com/threads/eu-study-shows-how-piracy-doesnt-affect-final-game-sales.6310/)). A 2024 academic working paper put the displacement figure for fresh games at about **20 percent in week one, decaying to about 5 percent by week six** ([Slashdot summary](https://games.slashdot.org/story/24/10/10/1846211/the-true-cost-of-game-piracy-20-of-revenue-according-to-a-new-study); the underlying paper is by a German economics group and is the load-bearing source). Translate that to giveaway keys: a recipient who actively requests a key resembles a week-six pirate more than a launch-week pirate, so a **5 to 10 percent cannibalisation prior** is defensible for press, streamer and bundle keys. Personal-gift keys are higher (the recipient is closer to the buyer pool), maybe **20 to 30 percent**.

The week-six analogy is a judgement call, not a measurement. The honest counter-reading: a request channel filters for higher genuine-interest users than the pirate channel does, which would push the cannibalisation prior *up* rather than down. Both directions are arguable from the same evidence; the priors below should be revised once Volley has its own data.

**Mike Rose (No More Robots)**, drawing on his publisher's 2018-2020 catalogue, frames the same question differently: *take wishlists just before launch and multiply by 0.2 to 0.3 for week-one sales* ([GDC Summer 2020](https://media.gdcvault.com/gdcsummer2020/presentations/Steam%20Wishlists%20GDC.pdf), [GDC Podcast ep 13](https://www.gamedeveloper.com/business/data-driven-indie-secrets-with-no-more-robots-mike-rose---gdc-podcast-ep-13)). **Jake Birkett (Grey Alien Games)** publishes the **Birkett Ratio** of week-one-sales-per-wishlist, which has drifted from ~0.36 in 2018 to ~0.2 today ([Birkett 2024](https://x.com/GreyAlien/status/1762155142361604278), [Game Developer](https://www.gamedeveloper.com/business/can-week-one-steam-sales-predict-first-year-sales-)). The two numbers do not agree on first read because they measure overlapping but distinct things (wishlist *conversion* vs sales *per* wishlist including organic), but both put a key that gets played displacing at most a fractional buyer.

Working priors (these are inferred Bayesian starting points, not measurements):

- Press keys: ~95 percent would not have bought.
- Streamer keys: ~90 percent would not have bought.
- Charity bundle keys: ~85 percent would not have bought (bundle buyers are price-sensitive).
- Personal community gifts: ~70 percent would not have bought.

Revise these once Volley has its own data.

## Grey market and chargebacks

Two load-bearing cases.

**Wube Software (Factorio).** 321 keys appeared on G2A; G2A's own internal investigation confirmed **198 illegitimate**. G2A paid Wube **$39,600**, ten times the documented chargeback fees ([PC Gamer](https://www.pcgamer.com/g2a-has-paid-factorio-studio-nearly-dollar40000-over-sale-of-illegitimate-keys/), [Game Developer](https://www.gamedeveloper.com/business/g2a-to-pay-i-factorio-i-dev-39-600-after-allowing-illegal-game-key-sales)). The signal: a single small indie tracked hundreds of fraudulent keys for one game, and the loss was real cash via chargebacks, not just opportunity cost.

**tinyBuild.** Claimed **$450,000** of grey-market exposure across **about 25,000 keys** ([MCV/Develop](https://mcvuk.com/development-news/tinybuild-we-lost-450000-in-revenue-to-grey-market-key-sellers/)). tinyBuild's CEO described stolen-card bundle purchases on their own store, immediate G2A relisting, then payment-processor shutdown from chargebacks. G2A disputed the framing ([Game Developer](https://www.gamedeveloper.com/business/g2a-hits-back-at-tinybuild-after-studio-claimed-it-lost-450k-to-key-reseller)).

The mechanism that matters for Volley: legitimate giveaway keys can be on-sold, but the bigger risk is that a public studio storefront issuing many keys becomes attractive to card-fraud bundle attacks. Mitigation is operational (Steam key issuance via curated channels only, no open storefront key sales) more than numerical. **Anything above about 5 percent of channel volume showing up on G2A is a fire alarm.**

## Press, streamers, and key services

**Cliff Harris (Positech)**, working from his own catalogue's data, found that a new Steam curator listing "had only a pretty small impact on sales" relative to blog mentions and ad spend ([Tips on interpreting your indie game sales data, 2015](https://www.positech.co.uk/cliffsblog/2015/01/18/tips-on-interpreting-your-indie-game-sales-data/)). The practical conclusion: do not chase curator quid-pro-quo. Zukowski reaches the same conclusion from postmortem aggregation; Harris's first-hand catalogue data is the stronger anchor.

For press and streamers, an indie postmortem aggregation cited in *How To Market A Game* gives a working number: **fewer than 500 keys at launch is insufficient; about 1,000 keys to press and streamers is a typical floor; pickup is often less than 10 percent** ([howtomarketagame.com 2021 roundup](https://howtomarketagame.com/2021/12/27/what-worked-in-2021/)). The literal pickup percentage remains Zukowski-only in surfaced sources; Birkett's ratio work covers the surrounding economics. 1,000 keys distributed converts to ~100 actual installs and a much smaller number of pieces of coverage. The cannibalisation cost of 1,000 unredeemed keys is essentially zero; the risk is concentration of redeemed keys at large streamers who then resell.

Streamer key services: **Keymailer** (founded by the Yogscast CEO), **Lurkit**, **Woovit** are the main three. Published per-platform conversion data is thin; the surfaced consensus is request-to-stream conversion in the **5 to 15 percent band** for indies with no marketing budget ([CloutBoost comparison](https://www.cloutboost.com/blog/keymailer-vs-lurkit-vs-terminals-vs-woovit-whats-the-best-key-distribution-service-for-game-publishers)). Lurkit is the most analytics-gated, biased toward larger streamers. For a Band 0 to 2 indie: enable Keymailer at launch, cap monthly key issuance at a number the studio would accept losing entirely, accept the long tail.

## Bundles

**Yogscast Jingle Jam.** Cumulative **£30.8m raised since 2011** ([jinglejam.co.uk](https://www.jinglejam.co.uk/tracker)). The bundle's selected indies ship keys for free; the studio receives no per-key payout but gains exposure to a six-figure audience and a charity-aligned brand association. For Volley's posture this is the canonical fit. Historical participants (Wandersong, A Short Hike) report sustained wishlist tail rather than a launch-week spike. Per-key revenue: zero direct, modest indirect.

**Humble Bundle paid bundles.** Standard split: **65 percent developer, 20 percent charity, 15 percent Humble** ([Wikipedia](https://en.wikipedia.org/wiki/Humble_Bundle)). Real-world per-key payout is small: *Monaco* netted approximately **$0.50 per copy** across 370,034 bundle units ([Game Developer postmortem](https://www.gamedeveloper.com/business/humble-bundle-insta-post-mortem)). A bundle inclusion of 50,000 units at $0.50 each is $25,000 net, comparable to several months of baseline funding. The cost is not cannibalisation but price-anchor damage; a player who got Volley for fifty cents in a bundle does not become a $9.99 buyer of Volley's sequel.

**Humble Store single-game.** 75 / 15 / 10 split (developer / charity / Humble).

## Free weekend dynamics

Steamworks documents Free Weekends as best-suited to **replayable or multiplayer games** with paired discounts to convert trial players ([Steam partner docs](https://partner.steamgames.com/doc/marketing/discounts/freeweekends)). Post-promotion review-velocity bump runs about four weeks. *Among Us* and *Fall Guys* going free-to-play are not analogues for paid-indie free weekends; both relied on cosmetic or platform-fee monetisation. **Inference for Volley: a Free Weekend is a Band 3+ tool.** Below that the audience is too small to absorb the post-promo dip.

This claim is **inferred**, not anchored to a practitioner Band-1-2 Free Weekend postmortem; the closest adjacent voice is Cliff Harris's writing against deep discounts ([The deep discount era is over, 2016](https://www.positech.co.uk/cliffsblog/2016/01/01/the-deep-discount-era-is-over/)), which speaks to discount discipline broadly rather than Free Weekend specifically. Treat with appropriate confidence and revisit when a small-indie Free Weekend postmortem surfaces.

## Brand dilution

**Aseprite** rarely discounts. Best-ever discount: **$9.99 once, in February 2024** ([IsThereAnyDeal](https://isthereanydeal.com/game/aseprite/history/)). The mechanic Aseprite invokes is the Steamworks 30-day post-price-change discount cooldown ([Steamworks docs](https://partner.steamgames.com/doc/marketing/discounts)); the philosophical anchor is **Cliff Harris**, who has argued for years that the deep-discount habit is a trap for indies ([The deep discount era is over, 2016](https://www.positech.co.uk/cliffsblog/2016/01/01/the-deep-discount-era-is-over/)). **Mindustry** runs free on itch and paid on Steam; Steam gross is estimated at **$9.7m, net to Anuke ~$2.86m** ([Steam Revenue Calculator](https://steam-revenue-calculator.com/app/1127400/mindustry); these are estimates). The cases together support Volley's posture: free-on-some-surfaces does not kill paid sales when the paid surface is convenience-priced and the brand is consistent. No surfaced case of an indie clearly killed by over-giving; the failure mode is more often invisible (sales never materialise because nobody knows the game).

## Per-band give-ceilings

Volley's bands need a simple model. Take the lower funding threshold of each band, divide by Steam's net to the developer (about 70 percent of $price after Valve's 30 percent cut, with USD/GBP at ~0.80 throughout), get a paid-unit floor. Cap total giveaway keys at the conversion-adjusted equivalent of **5 percent of paid units** for Band 0 to 2, **3 percent** for Band 3+. The conversion adjustment uses a **10 percent blended cannibalisation rate**.

That 10 percent figure assumes a channel mix of roughly **50 percent streamer (10% prior), 25 percent press (5% prior), 15 percent charity bundle (15% prior), 10 percent personal gift (30% prior)**: weighted blend ≈ 10 percent. A studio with a heavier personal-gift mix gets a higher blended rate and the caps shrink proportionally; recompute if Volley's actual mix drifts.

The caps below use each band's **floor** (the lower funding threshold). At the *upper* end of a band, the paid-unit floor rises and the cap rises with it; Band 4 at the £500,000 cap computes to ~44,683 paid units, which gives a 3% cap of ~1,340 keys and an effective key cap of ~13,400 (about 2.5x the table's floor-based 5,360). Use the floor numbers as conservative working bounds; the higher numbers are headroom available once the studio is genuinely at the top of a band.

| Band | Price (USD) | Funding floor (GBP) | Net per unit (~GBP) | Paid units floor | Raw % cap | Effective key cap |
|---|---|---|---|---|---|---|
| 0 | $2 | £0 | £1.12 | 0 (baseline-funded) | n/a | ~500 keys ceiling regardless |
| 1 | $3 | £10,000 | £1.68 | ~5,950 | 5% = ~298 | **~2,975 keys** |
| 2 | $5 | £25,000 | £2.80 | ~8,930 | 5% = ~447 | **~4,465 keys** |
| 3 | $9.99 | £75,000 | £5.59 | ~13,420 | 3% = ~403 | **~4,025 keys** |
| 4 | $19.99 | £200,000 | £11.19 | ~17,873 | 3% = ~536 | **~5,360 keys** |

Arithmetic check, Band 1: £10,000 ÷ £1.68 = 5,952 units; 5 percent = 297.6; ÷ 10 percent cannibalisation rate = 2,976. Verified.

The key cap is the *upper bound* at which giving everything away still leaves the band's revenue intact assuming 10 percent of recipients would have actually bought. The studio runs well under it. **Recommended operating budget: a quarter to a third of the cap.**

## First-12-months recommendation

For Volley sitting at Band 0 to 1 in year one:

- **Press and curator keys: 200.** Sent on request, no targeted curator quid-pro-quo per Zukowski. Pickup ~10 percent, ~20 actual eyes.
- **Streamer keys via Keymailer / Lurkit: 500 cap, issued over 12 months.** Auto-decline tiny channels, manual approve mid-tier. Expect about 50 streams.
- **Charity bundle (Jingle Jam application year one if accepted): 1 inclusion, unlimited keys to bundle buyers.** Treat as marketing equivalent to a five-figure paid campaign the studio would not otherwise run. Cap to one bundle per year to avoid price anchoring.
- **Community gifting and giveaway streams: 200.** Studio-initiated giveaways through devlog and newsletter, plus copies donated to charity streamers running unprompted.
- **SpecialEffect One Special Day: a day's revenue, not keys.** Already in the [funding matrix](funding-matrix.md).

**Total non-bundle keys, year one: ~900.** Comfortably under the Band 1 cap of ~2,975. If a Jingle Jam slot lands, total give-volume jumps by 50,000+ but those keys are bundle-locked and do not reach G2A directly (Humble and Yogscast bundle keys carry redemption restrictions).

## How "watermarking" actually works

There is no cryptographic watermark in a Steam key itself. The "watermark" is shorthand for **tracked-distribution logging**. The mechanism: when keys are requested from the Steam Partner backend, request them in named batches and download the CSV; maintain a per-recipient log mapping each key string to its channel and recipient (`XXXX-YYYY-ZZZZ → press batch, emailed to journalist@pcgamer.com on 2026-03-12`).

Detection is the harder bit. Standard practice is **honeytrap purchasing**: buy a copy of the game from G2A every quarter, inspect the key, and trace the key string back to the distribution log. That tells the studio which channel leaked. Wube Software (Factorio) used exactly this approach; the 198 confirmed-illegitimate keys were identified by matching G2A listings against Wube's distribution records.

Better than after-the-fact watermarking is **issuance discipline upstream**. Streamer key services like **Keymailer / Lurkit / Woovit** carry their own anti-resale infrastructure (rate limits, viewer verification, sometimes single-activation tracking). Steam's **free game preview** mode grants revocable in-account access to specific reviewers without issuing a transferable key. Personalised key emails (`Hi [name], here's your Volley key for review`) add small friction that makes resale less convenient without cost. The watermark log is diagnostic; the issuance discipline is preventive.

## Operational rules

- **No open key sales from the studio's own store.** This is the only defence against the tinyBuild card-fraud-then-G2A scenario. Keys are issued via Steam's curated key system (Keymailer, Lurkit, manual curator approvals) only.
- **No bulk key issuance to anyone outside Steam's curated key system.** Same reason.
- **Never commit to open-ended matching of a community fundraising total.** Per `project_marketing_public_good`: cap pledges at a fixed amount (e.g. £100, £500, £5K depending on band) so the studio's exposure is bounded.
- **Treat the per-band cap as ceiling, not target.** Recommended operating budget is a quarter to a third of the ceiling.
- **Audit a sample of issued keys for grey-market resale once a quarter.** Watermark a small subset, check G2A six months later. Anything above 5 percent of channel volume showing up there is a fire alarm.

## Open questions

- The 2024 piracy-displacement paper (German economics group, ~20 percent week-one, ~5 percent week-six) needs a direct citation; the doc currently works from secondary coverage. The PDF is worth pulling before the doc becomes a public reference.
- Jingle Jam acceptance criteria for first-time UK indies should be confirmed directly with Yogscast Games before sizing the year-one application.
- A Keymailer per-key resale audit (taking 50 keys, watermarking, checking G2A six months later) would give Volley its own number rather than relying on tinyBuild's.
- The percentage of bundle recipients who become long-term audience is essentially unanswered in the public literature. Worth a direct ask in a GameDiscoverCo Discord or paid-tier query.
