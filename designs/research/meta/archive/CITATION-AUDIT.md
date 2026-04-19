# Citation Audit

Audit of inline citations in `drafts/section-01-the-mark.md` through `section-14-close.md` against the bibliography in `drafts/section-15-sources.md`.

Methodology: extracted every `#ref-N` inline reference, mapped to bibliography entries, then read the surrounding sentence at each inline location and compared the cited source's content to the claim. Web-fetched sources where the bibliography text was ambiguous or the quotation was load-bearing.

Total inline citation numbers in use: 154 distinct numbers across 1-169, omitting [10]-[40] gaps where intentional. Bibliography contains entries [1]-[144] and [148]-[169].

---

## Mismatches (citation does not support the claim)

### [7] — Zukowski "tuned" / "set expectation of success" quote

- **Inline location:** `section-01-the-mark.md`, paragraph 3 (the Zukowski paragraph). Sentence: *"The Steam algorithm, he has written, 'is "tuned" and has a set expectation of what success looks like. And if you reach those thresholds of success, Steam shows more of your game, and if sells less than your game is shown less' [7]."*
- **Bibliography entry:** Chris Zukowski, "Killing the myths behind Steam's visibility", How To Market A Game (September 2023). https://howtomarketagame.com/2023/09/04/killing-the-myths-behind-steams-visibility/
- **Mismatch:** Web-fetch of the cited article does not contain the quoted phrase. The article addresses Steam visibility myths but never says the algorithm is "tuned" or that it has "a set expectation of what success looks like" with thresholds that increase or decrease visibility. The article's actual stance is closer to "there is no magic number" and "Steam doesn't make permanent decisions about your game".
- **Proposed fix:** Track down the originating Zukowski post (likely a different How To Market A Game piece, possibly his "How to predict launch" or "Algorithm" series) and update the citation. If the quote cannot be located, paraphrase or drop the quoted clause and keep only Zukowski's broader thesis.

### [8] — Jim Butcher bear quote

- **Inline location:** `section-01-the-mark.md`. *"His preferred line is one he borrows from Jim Butcher: 'You don't have to run faster than the bear to get away. You just have to run faster than the guy next to you' [8]."*
- **Bibliography entry:** Chris Zukowski, "How many wishlists should I have when I launch my game?" https://howtomarketagame.com/2022/09/26/how-many-wishlists-should-i-have-when-i-launch-my-game/
- **Mismatch:** None — verified the quote appears in the cited article. Zukowski uses the line twice.
- **Proposed fix:** No change. (Listed here for completeness — initially flagged but verified clean.)

### [91] — Octoverse 2024 geographic projections

- **Inline location:** `section-09-inclusivity.md`. *"GitHub's Octoverse 2024 reports India is on track to overtake the United States in contributor numbers by 2028, with year-on-year contributor growth above 25% in Nigeria, Brazil, and the Philippines [91]."*
- **Bibliography entry:** GitHub Octoverse 2024 geographic distribution coverage. https://github.blog/news-insights/octoverse/octoverse-a-new-developer-joins-github-every-second-as-ai-leads-typescript-to-1/
- **Mismatch:**
  1. The Octoverse projection is **2030**, not 2028. The cited blog post forecasts India reaching ~57.5M developers by 2030 vs US at ~54.7M; it does not name 2028.
  2. The "year-on-year contributor growth above 25% in Nigeria, Brazil, and the Philippines" claim is not supported by the cited URL. The post mentions Nigeria's projected growth and Brazil's #4 ranking but does not give YoY percentages of the form claimed.
- **Proposed fix:** Change "2028" to "2030" (or "by the end of the decade"). Either remove the 25% YoY claim or replace it with the actual figures the Octoverse 2024 post provides — e.g., Brazil at ~3.2M net new developers, Nigeria's projected millions added — and rephrase accordingly. If the 25% figure has a source, locate and add it as a separate citation.

### [44] — Maddy Thorson Twitter thread on Assist Mode wording

- **Inline location:** `section-05-transparency.md`. *"Thorson agreed, and the description was rewritten with narrative designer Kathy Jones to: 'If the default game does not prove to be challenging yet rewarding due to inaccessibility, we hope that Assist Mode will still give you that experience' [44]."*
- **Bibliography entry:** Maddy Thorson, Twitter thread on Assist Mode wording. https://twitter.com/maddythorson/status/1352404112260775936
- **Mismatch (suspected, not confirmed):** Could not fetch the tweet (rate-limited). However, the status ID `1352404112260775936` corresponds to **January 2021**, almost three years after Celeste's January 2018 launch. The Vice article cited at [43] dates to 2018 and credits Lexa + Kathy Jones for the rewrite around launch. The dates don't line up unless this 2021 tweet is a retrospective; either way, it's not the rewrite-moment artefact that the inline citation implies.
- **Additional concern:** The wording the essay attributes as the *new* Assist Mode description differs from what the Vice piece reports as the new wording ("…we hope that you can still find that experience with Assist Mode."). The essay's quoted "rewrite" text and Vice's quoted "rewrite" text are not the same sentence. One of them is either the in-game text at a different patch revision or a misquote.
- **Proposed fix:** Verify the cited tweet's content directly. Either replace [44] with a primary source for the new wording (the in-game string itself, a patch notes entry, or the actual Twitter exchange between Lexa and Thorson from 2018), or rewrite the surrounding paragraph to reflect what each source actually documents. Reconcile the new-wording text against [43] before publishing.

### [43] — Vice article on Celeste Assist Mode

- **Inline location:** `section-05-transparency.md`. The original Assist Mode description quoted in the essay: *"Celeste is intended to be a challenging and rewarding experience. If the default game proves inaccessible to you, we hope that Assist Mode will allow you to still enjoy it in a way that suits your style of play" [43].*
- **Bibliography entry:** Vice, "Celeste Assist Mode change and accessibility". https://www.vice.com/en/article/celeste-assist-mode-change-and-accessibility/
- **Mismatch:** The Vice article quotes Celeste's original wording around the word "essential" (not "intended"), and quotes the new wording as "…we hope that you can still find that experience with Assist Mode." That doesn't match what the essay quotes as either the original or the rewrite. The Vice piece does support the headline claim (Lexa pointed out the wording, the team rewrote it) but does not source the specific quoted strings the essay attributes to it.
- **Proposed fix:** Either source the exact quoted strings to a primary artefact (in-game text, GitHub commit on the Celeste source repo, or the actual Twitter thread) or rewrite the passage as paraphrase rather than verbatim quotation. Consider that the essay's quoted "before" and "after" may both be from the in-game strings file, in which case [45] (the Celeste source repo) is a better citation than [43]/[44].

### [42] — Celeste Wiki "Cheat Mode" rename

- **Inline location:** `section-05-transparency.md`. *"…shipped Assist Mode in the base game on 25 January 2018, originally called 'Cheat Mode' until Thorson renamed it because 'Cheat' felt judgmental [41][42]."*
- **Bibliography entry:** Celeste Wiki, "Assist Mode" entry. https://celeste.ink/wiki/Assist_Mode
- **Mismatch (unverified — page returned 403):** Could not fetch celeste.ink/wiki/Assist_Mode to confirm the "Cheat Mode" naming history is on that page. The "Cheat Mode" rename is widely attested but the specific source for it is more commonly Maddy Thorson's own writing/interviews than the wiki.
- **Proposed fix:** Confirm the wiki entry contains the rename story; if not, swap [42] for a Thorson interview or developer-commentary source.

### [60] — CG Channel Arrowhead 2026

- **Inline location:** `section-06-open-source-extreme.md` (implicit — Arrowhead listed among Blender corporate backers).
- **Bibliography entry:** CG Channel, "Arrowhead Game Studios backs the Blender Development Fund" (2026). https://www.cgchannel.com/2026/02/arrowhead-game-studios-backs-the-blender-development-fund/
- **Mismatch:** Not a content mismatch per se — flagged because a 2026 article date suggests this should be verified the page actually exists and the figures (€30,000/year for Arrowhead) are present. Did not web-fetch.
- **Proposed fix:** Verify the URL resolves and the €30k/year figure is in the source.

---

## Orphan bibliography entries (no inline citation points at them)

These entries appear in `section-15-sources.md` but no `#ref-N` link in the essay points at them.

| N | Entry | Notes |
|---|---|---|
| 35 | Friday Facts #1 (Factorio) | Marked "no longer cited" — intentional. Consider deleting from bibliography to clean up. |
| 36 | Factorio Friday Facts archive | Marked "no longer cited" — intentional. Same. |
| 37 | Friday Facts #250 | Marked "no longer cited" — intentional. Same. |
| 38 | Friday Facts #229 | Marked "no longer cited" — intentional. Same. |
| 39 | Friday Facts #288 | Marked "no longer cited" — intentional. Same. |
| 40 | Factorio on Wikipedia | Marked "no longer cited" — intentional. Same. |
| 46 | Celeste Player README (NoelFB/Celeste GitHub) | Genuine orphan. Either drop or add an inline citation when discussing the open-sourced player code in `section-05-transparency.md` paragraph that already cites [45]. |
| 47 | Maddy Thorson, "Is Madeline Canonically Trans?" Medium | Genuine orphan. Not used in current draft. The essay's transparency / inclusivity sections do not address Madeline's transness. Either drop or add a sentence that uses it. |
| 70 | Software Sessions interview with Courtland Allen | Genuine orphan. Lineage section cites Levels and Nomad List ([68], [69]) but not Indie Hackers / Allen. Either drop or weave a sentence in. |

Recommendation: delete the [35]-[40] entries entirely (they're labelled "no longer cited" but still consume source-list real estate), or move them to a "removed" sub-section in `section-15-sources.md`. For [46]/[47]/[70], decide whether to use or remove.

---

## Broken inline refs (number with no entry)

None. Every inline `#ref-N` resolves to a bibliography entry.

Numbers 145, 146, 147 do not exist in the bibliography and are also not referenced inline. They are simply gaps from earlier removals — no broken refs.

---

## Duplicate citations

None found in the strict sense (no two different sources sharing one number, no two numbers pointing at the same source).

A few sources are cited many times across multiple sections — these are reuse, not duplicates:

- [12] Hollow Knight Wiki Kickstarter: cited 3 times in `section-03-kickstarter.md` for different facts (concept art, AU$57,138/2,158 backers, sales-to-2025 figures). The single source is asked to support all three; the Kickstarter raised-amount and the sales numbers really live across [12]+[13]+[15], which the essay does include alongside, so the load is shared.
- [13] Source Gaming Team Cherry interview: cited 3 times for related Gibson/Pellen quotes — verified clean.
- [85] Asparouhova *Working in Public*: cited in both `section-08-apprenticeship.md` and `section-09-inclusivity.md`. Both citations are appropriate; the book covers both topics.
- [31] PsychOdyssey: cited in `section-04-devlog.md` and `section-10-valve.md`. Appropriate cross-use.

---

## Verified clean (rolled-up summary by citation number range)

Spot-checked verifications via web-fetch where the claim was load-bearing or the citation looked suspicious. Numbers below were either directly verified or are routine bibliographic references whose content matches the inline claim on a face-value reading.

- **[1]-[6]** Macro industry stats. Routine — Steam/Kotaku/GDC/Ukie sources match the cited figures.
- **[8]** Zukowski Jim Butcher bear quote — **verified via web-fetch**, quote present in source.
- **[9]-[11]** GameDiscoverCo wishlist conversion, Double Fine Adventure Kickstarter, Broken Age. Source-claim pairings look correct on inspection.
- **[12]-[16]** Team Cherry / Hollow Knight cluster. Quotes for [13] and [16] **verified via web-fetch** — Gibson/Pellen quotes correct.
- **[14]** Hungry Knight: Ludum Dare 27, Aug 2013, 1/5 score — **verified via web-fetch**, all match.
- **[17]-[27]** Stardew Valley, Dwarf Fortress, Terraria clusters. Routine; statements match.
- **[28]-[34]** Massive Chalice, Psychonauts 2, Double Fine acquisition, PsychOdyssey, Caves of Qud. Routine.
- **[41], [45]** Celeste Wikipedia + GitHub source. Routine.
- **[48]-[52]** Mindustry / Shapez / Shapez 2 sales figures. Routine; figures align with sources.
- **[53]-[60]** Godot, Blender, FNA funding cluster. **[55] verified** (Re-Logic "predatory" + $100k each). **[60]** flagged for sanity-check on URL.
- **[61]-[63]** Spolsky, Stallman, Anthropy. Standard citations of well-known texts.
- **[64]-[73]** Lineage section. Torvalds Usenet post, Raymond, Buffer, Levels, Benkler, Shirky, Doctorow. Routine.
- **[74]-[85]** Apprenticeship section macro sources. Routine.
- **[86]-[99]** Inclusivity section. Routine; Naughty Dog, Microsoft, Forza, Ian Hamilton, Coffee Talk, Until Then, Liyla, McRuer.
- **[100]-[121]** Valve section. **[107] $57M Workshop payout verified via web-fetch**, matches.
- **[122]-[136]** AI labs / safety summit cluster. Routine institutional citations.
- **[137]-[144]** Hicks, Silksong, Buffer 2025, Terraria/Re-Logic cluster. **[144] verified via web-fetch** ($1k/month standing sponsorship to Godot and FNA, "predatory" wording).
- **[148]-[155]** Lucas Pope cluster. Routine; Pope's own devlogs and PC Gamer write-up.
- **[156]-[161]** University pipeline cluster. Handshake, NACE, Waterloo, Northeastern, Sydney, Berkeley. Routine.
- **[162]** VG Insights PC market share. Routine.
- **[163]-[169]** Anthropic RSP / METR / safety follow-through cluster. Routine.

---

## Summary recommendations

1. **Highest priority:** Resolve [7] — the Zukowski "tuned" quote does not appear in the cited article. Either find the actual source or drop the quoted clause.
2. **High priority:** Fix [91] — change 2028 to 2030 (or strip the year), and remove or re-source the Nigeria/Brazil/Philippines 25% YoY claim, which is not in the cited Octoverse blog post.
3. **High priority:** Reconcile [43] / [44] / [45] for the Celeste Assist Mode rewrite quotes. The two verbatim strings the essay quotes do not match what the Vice article (cited at [43]) reports. The 2021 tweet ID at [44] is suspicious for a 2018 event.
4. **Medium priority:** Verify [42] (celeste.ink wiki for "Cheat Mode" rename) — page returned 403; cannot confirm the source supports the claim.
5. **Medium priority:** Verify [60] resolves (2026 URL, sanity check).
6. **Cleanup:** Decide on the orphans — delete [35]-[40] outright, and either use or drop [46], [47], [70].
