# The Agile Estimation Debate: story points, velocity, #NoEstimates

Research compiled 2026-05-26. Background for how Shuck thinks about estimation in its own process.

**One-line answer:** The reduction-to-time claim is well-supported and is conceded, in part, by the leading proponents themselves. Mike Cohn states plainly that "effort is measured in time," and SAFe ties a story point to a literal half-day-develop-plus-half-day-test reference and gives every developer "eight points" per iteration. The strongest defence is not that points aren't time, but that they are a *distribution* over time rather than a fixed conversion, and that relative sizing survives differences in individual speed. The #NoEstimates camp (Zuill, Duarte, Holub, late-period Jeffries) accepts the reduction and treats it as the indictment, not the defence.

---

## Thread 1: The case FOR story points

### Mike Cohn: effort = volume + complexity + risk + uncertainty
- "Story points are an estimate of the effort involved in doing something."
- "Complexity is a factor ... But it is not the only factor." "The amount of work to be done is a factor. So, too, are risk and uncertainty."
- Canonical illustration: licking 1000 stamps vs simple brain surgery (equal effort, wildly different complexity), so points track effort, not complexity.
- Source: [Story Points Are Still About Effort](https://www.mountaingoatsoftware.com/blog/story-points-are-still-about-effort); [InfoQ summary](https://www.infoq.com/news/2010/07/story-points-complexity-effort/).

### How proponents argue points are NOT time (relativity / speed-independence)
- "One story point equals eight hours" is rejected because it makes points "entirely dependent on who is doing the work."
- Cohn frames the link as a *distribution*: "one point equals a distribution with a mode of x, two points ... a mode of 2x."
- Hinge of the debate: Cohn does not deny the time link, he affirms it while resisting a fixed rate. "Effort is measured in time ... it doesn't mean teams should say 'one story point equals eight hours.'"
- Source: [Don't Equate Story Points to Hours](https://www.mountaingoatsoftware.com/blog/dont-equate-story-points-to-hours).

### SAFe: an explicit, near-literal time anchor
- Glossary: a story point estimates "volume, complexity, knowledge, and uncertainty" (complexity only one of four).
- Normalization: find a "1" as a story "that would take about a half-day to code and a half-day to test"; "give every developer-tester eight points for a two-week iteration (one point for each ideal workday ...)."
- Qualifier: "Except for the first Iteration, one Story Point does not equal one day of effort, and the current Velocity is needed to predict the current duration/effort." So velocity is the points-to-time converter.
- Source: [SAFe glossary](https://framework.scaledagile.com/blog/glossary_term/story-point); [wibas: Normalized Story Points](https://www.wibas.com/en/blog/articles-1/estimation-with-normalized-story-points-really-343); [wibas: tricky capacity slide](https://www.wibas.com/en/blog/articles-1/a-tricky-slide-about-story-points-and-capacity-in-safe-r-and-how-to-get-it-right-344).

---

## Thread 2: The case AGAINST / #NoEstimates

### Woody Zuill (coined the hashtag, 2012)
Estimates "seemed to misinform the decisions they are intended to inform." Claim is conditional: where a decision can be made without an estimate, skip it. Index: [zuill.us/beyond-estimates](https://zuill.us/WoodyZuill/beyond-estimates/) (verbatim core argument is in his Oredev 2013 talk, not the index page).

### Vasco Duarte ("Story Points considered harmful", *NoEstimates* book)
Positive proposal is **story counting**, not point summing: count items delivered, forecast the delivery rate (items / time) from 3 to 5 iterations, often take stories into a sprint "without even sizing those." Empirical plank: with small, roughly-uniform stories (about a day), story-count forecasts are as accurate as point forecasts, so points add ceremony without predictive power. Source: [InfoQ Q&A](https://www.infoq.com/articles/book-review-noestimates/).

### Allen Holub (points invented to *hide* time)
Quotes Jeffries: "Story Points were invented to obfuscate duration so that certain managers would not pressure the team," then calls using them as an effort estimate "bizarre." "Estimates are always inaccurate, usually wildly so." "Velocity is something you measure, not something you can control." Source: [#NoEstimates, An Introduction](https://holub.com/noestimates-an-introduction/); [KPIs, Velocity, and Other Destructive Metrics](https://holub.com/kpis-velocity-and-other-destructive-metrics/).

### Ron Jeffries: "Story Points Revisited" (the keystone)
- "I may have invented story points, and if I did, I'm sorry now." "I certainly deplore their misuse."
- "Using them to predict 'when we'll be done' is at best a weak idea." "Tracking how actuals compare with estimates is at best wasteful."
- Origin: stories were first estimated in time, then "Ideal Days," then "we started calling our 'ideal days' just 'points'."
- Narrow retraction: anti-*prediction*, not anti-relative-sizing. (The "kicked to the curb" line is Chet Hendrickson, not Jeffries; attribute carefully.)
- Source: [Story Points Revisited](https://ronjeffries.com/articles/019-01ff/story-points/Index.html).

---

## Thread 3: Do story points collapse to time?

**Verdict: substantiated for predictive use, with one genuine residual defence.**

Reduction evidence:
1. Jeffries' origin admission: points are renamed ideal days (a time unit times a ~3x load factor).
2. Holub via Jeffries: if the *purpose* was to obfuscate duration, duration is what's underneath.
3. Cohn's concession: "effort is measured in time," because that's how people answer "when will it be delivered."
4. SAFe's mechanism: the "1" is half-day plus half-day; capacity is eight points/dev/iteration; velocity converts thereafter.
5. Duarte's empirical reduction: if counting forecasts as well as summing, point magnitudes carry no info beyond throughput-over-time.

Residual defence (what does NOT reduce to a single number):
1. **Distribution, not equation** (Cohn): a point maps to a distribution of hours, not a scalar; collapse only happens if you pin a fixed rate.
2. **Speed-independence / relativity** (Cohn): two people can agree B is twice A while disagreeing on hours; hours are person-specific, that shared relative judgment is real information.
3. Velocity as a measured, self-correcting rate (Holub's "measure not control", read charitably) is a forecast tool, not a commitment.

**The precise claim that survives:** story points add no information over time-based forecasting that you couldn't get from sized-but-uncounted throughput, *except* the speed-independence of relative comparison, and once velocity is applied to forecast a date, even that is consumed into a time estimate. The #NoEstimates response: that residual is not worth the ceremony when small uniform stories let you forecast by counting.

---

## Loose ends
- Zuill verbatim: chase the Oredev 2013 talk transcript.
- SAFe primary normalization page is login-gated; the half-day and eight-points rules here are quoted via wibas (a SAFe consultancy) and *SAFe Distilled*.

## Sources
- [Story Points Are Still About Effort, Mike Cohn](https://www.mountaingoatsoftware.com/blog/story-points-are-still-about-effort)
- [Don't Equate Story Points to Hours, Mike Cohn](https://www.mountaingoatsoftware.com/blog/dont-equate-story-points-to-hours)
- [Do Story Points Relate to Complexity or Time?, InfoQ](https://www.infoq.com/news/2010/07/story-points-complexity-effort/)
- [Story Point glossary, Scaled Agile Framework](https://framework.scaledagile.com/blog/glossary_term/story-point)
- [Estimation with Normalized Story Points? Really?, wibas](https://www.wibas.com/en/blog/articles-1/estimation-with-normalized-story-points-really-343)
- [A tricky slide about Story Points and Capacity in SAFe, wibas](https://www.wibas.com/en/blog/articles-1/a-tricky-slide-about-story-points-and-capacity-in-safe-r-and-how-to-get-it-right-344)
- [Beyond Estimates index, Woody Zuill](https://zuill.us/WoodyZuill/beyond-estimates/)
- [Q&A with Vasco Duarte on the NoEstimates Book, InfoQ](https://www.infoq.com/articles/book-review-noestimates/)
- [#NoEstimates, An Introduction, Allen Holub](https://holub.com/noestimates-an-introduction/)
- [KPIs, Velocity, and Other Destructive Metrics, Allen Holub](https://holub.com/kpis-velocity-and-other-destructive-metrics/)
- [Story Points Revisited, Ron Jeffries](https://ronjeffries.com/articles/019-01ff/story-points/Index.html)
- [#noestimates is just story points done right, Magnus Dahlgren](https://magnusdahlgren.com/2017/03/23/noestimates-just-story-points-done-right/)
