# Story Points Are Time Wearing a Costume

Research compiled 2026-05-26. Background for how Shuck thinks about estimation in its own process.

## The man who invented them is sorry

In 1999, on the C3 payroll project at Chrysler, a team started writing the time each story would take onto index cards. The numbers made managers nervous, so the team renamed them. Days became "ideal days", then ideal days became "points". The person who oversaw that renaming, Ron Jeffries, later put it plainly: "I may have invented story points, and if I did, I'm sorry now."

He went further. "Using them to predict 'when we'll be done' is at best a weak idea." The most-cited tool in agile estimation arrived with its inventor's regret attached, and the regret is specific. Points were not built to measure a new thing. They were built to hide an old one.

Proponents will tell you that points measure complexity, or effort, or business value, and that the link to time is a misunderstanding peddled by managers who never read the books. Some of them are right about the managers. None of them escape the clock.

## What the proponents actually say

Mike Cohn is the most careful proponent, and he does not say points measure complexity. He says the opposite. "Story points are an estimate of the effort involved in doing something." Complexity is one input among several: "The amount of work to be done is a factor. So, too, are risk and uncertainty." His canonical illustration is licking a thousand stamps against performing simple brain surgery: equal effort, wildly unequal complexity, so the thing the points track cannot be complexity alone. The point of the example is to pry estimation loose from difficulty and pin it to effort.

The Scaled Agile Framework, the heavyweight enterprise version, makes the same move in its glossary. A story point estimates "volume, complexity, knowledge, and uncertainty". Complexity is one of four. On the surface this is a system designed to be more than a stopwatch.

Points are effort, effort is a blend of work and risk and the unknown, and reducing all of that to a number of hours throws away information the blend was meant to keep. The blend is real. The question is what the blend is denominated in.

## The defence that almost works

"One story point equals eight hours." Cohn rejects the equation. Pin a point to a fixed number of hours and the point becomes "entirely dependent on who is doing the work". A senior developer and a junior will disagree on the hours for the same task and both be correct, because the hours are theirs, not the task's. The shared judgement that survives the disagreement is the relative one: both can agree this story is twice that story, even while they price the hours differently. Relative size is speed-independent in a way an hour estimate can never be. That is real information, and it is information that a raw time estimate destroys.

Cohn's refinement is sharper still. A point does not map to a number of hours; it maps to a distribution of them. "One point equals a distribution with a mode of x, two points a distribution with a mode of 2x." The collapse to time only happens if you flatten that distribution to a single number and fix the rate. Refuse the fixed rate and the point stays a spread, a hedge against the variance that any single hour figure pretends away.

Points are relative, relativity is speed-independent, and the relationship to time is a distribution rather than an equation.

## Where the costume slips

"Effort is measured in time." Cohn writes that in the same breath as his warning against the eight-hours equation. He does not deny that points reduce to time; he affirms it, and asks only that the conversion stay loose. The argument was never that points are not time. It was that points are time expressed as a distribution rather than a scalar. A distribution over hours is still hours. However wide the error bars run, the axis they are measured on has not changed.

SAFe drops the costume entirely. Its normalisation procedure tells a team to find a reference "1": a story "that would take about a half-day to code and a half-day to test". Then it tells you to "give every developer-tester eight points for a two-week iteration", one point for each ideal workday. A point is a day. The framework says so, in workdays, on the first iteration. The only qualifier is that after the first iteration the rate floats: "one Story Point does not equal one day of effort, and the current Velocity is needed to predict the current duration." The qualifier does not break the link to time. It names the machine that maintains it. Velocity is the converter that turns points back into a date.

And velocity is the whole game, because velocity is what every team does with the points. Nobody estimates in points and then stops. They sum the points, divide by the velocity, and read off a date. The relative sizing that was speed-independent gets multiplied by a team-specific rate measured in points per unit of time, and out the far end comes a duration. The one property that did not reduce to time, the speed-independence, is consumed by the one operation everyone performs. You cannot forecast with velocity and keep the speed-independence. The forecast spends it.

## The other side already knew

Woody Zuill coined the hashtag in 2012 with a conditional claim, not a slogan: where a decision can be made without an estimate, the estimate is waste, because estimates "seemed to misinform the decisions they are intended to inform". The camp's case is built on agreement, not accusation. Allen Holub put the history bluntly, quoting Jeffries on the origin: points "were invented to obfuscate duration so that certain managers would not pressure the team". If the purpose of the unit was to obscure duration, then duration is the thing underneath the unit. You do not build a disguise for something that is not there.

Vasco Duarte supplied the empirical blade. His proposal is story counting rather than point summing: count the items delivered, forecast the delivery rate over the last three to five iterations, and often take stories into a sprint "without even sizing those". His claim is that with small, roughly uniform stories, a forecast built from counting items is as accurate as one built from summing points. If the magnitudes carry no predictive information that throughput over time does not already carry, then the magnitudes are ceremony. The points add a step and subtract nothing.

Holub's line on velocity closes the loop: it is "something you measure, not something you can control". A measured rate is a useful forecasting instrument. It is not a thing a team can be held to, and the moment a manager treats it as a commitment, the obfuscation Jeffries described has failed in the other direction. The number meant to shield the team becomes the leash.

## What survives, and what eats it

Two people who cannot agree on the hours a task will take can still agree that B is twice A. That relative sizing is speed-independent, and it is genuine information worth having. A distribution carries more than a point estimate, and pretending a task takes exactly six hours is a worse lie than admitting it takes somewhere between four and twelve. These are not nothing. The proponents are defending something that exists.

But it does not survive contact with use. The instant you apply velocity to turn a backlog of points into a delivery date, the speed-independence is converted into a team-specific duration, and the distribution is collapsed into the single number the date requires. The residue that resisted reduction is exactly the residue that forecasting consumes. What you are left holding is a time estimate with extra steps, and the extra steps were added, on Jeffries' own testimony, to keep a manager from reading the time estimate too directly.

The claim narrows to this. Story points add no predictive information over time-based forecasting that you could not get from sized-but-uncounted throughput, with one exception: the speed-independence of relative comparison. And the moment velocity forecasts a date, even that exception is spent. The #NoEstimates answer is the practical one. If small uniform stories let you forecast by counting, the residual is not worth the ceremony it costs to maintain.

## How Shuck reads this

A solo studio with an AI assistant in the loop has no manager to obfuscate duration from. The political reason points exist does not apply here, and the work is small-batch and roughly uniform by the nature of how it is shipped: one fix, one mechanic, one design doc at a time. The conditions Duarte names for counting to match summing are the conditions Shuck already works under.

So the practice is to size for shared understanding when sizing genuinely clarifies a piece of work, and to forecast by counting throughput rather than summing magnitudes. Where a point would only be a day wearing a costume, the costume comes off. The clock was always underneath.

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
