# Estimating Without Estimates

Research compiled 2026-05-27.

## The ritual every sprint repeats

James Grenning defined and named Planning Poker in 2002, after a planning meeting where two senior engineers dominated while six other people sat out, and the rite descends from Wideband Delphi, the method Barry Boehm adapted in the 1970s. Turning the cards at once strips out anchoring and seniority. The number that lands is the team's, not the loudest voice's, and it arrives as a by-product of a conversation about the work rather than as the point of the meeting.

Points completed each sprint, averaged, become velocity, and velocity slopes the burndown toward a date. The team reads that slope and plans against it, trusting it because it comes from the team's own measured output rather than from a manager's wish.

The cards skip 4, 6, and 7 because the widening Fibonacci gaps encode growing uncertainty at larger sizes and force a decisive bucket instead of a haggle over six versus seven. And almost no one at the table, asked what a point measures, can answer. The foundation under it has never been read.

## How a unit of time became a unit of nothing

March 1996. The Chrysler Comprehensive Compensation System, a Smalltalk payroll replacement, had not yet printed a single paycheck. Kent Beck became project leader that month and brought Ron Jeffries onto the team. Extreme Programming was refined on this project; Beck's *Extreme Programming Explained* followed in October 1999. The unit of estimation now used by teams who have never heard of Chrysler was born here.

It began with a name that meant something. Ron Jeffries, who co-founded Extreme Programming with Beck and Ward Cunningham, recalls in *Story Points Revisited* (23 May 2019) that stories were sized in "Ideal Days," which he glosses as "how long it would take a pair to do it if the bastards would just leave you alone." The name said what it counted: days.

Reality declined to cooperate. "We multiplied Ideal Days by a 'load factor' to convert to actual implementation time," Jeffries writes. "Load factor tended to be about three: three real days to get an Ideal Day's work done." The unit did not break in the code. It broke in the conversation with stakeholders, who, in his account, "were often confused by how it could keep taking three days to get a day's work done."

The fix was a deletion. "We started calling our 'ideal days' just 'points'," Jeffries writes. "So a story would be estimated at three points, which meant it would take about nine days to complete." Removing the word "days" removed the promise embedded in it, that one estimated day would be one calendar day. The number was made dimensionless on purpose, so that the conversion to calendar time would be supplied later by velocity rather than assumed at the moment of estimation.

The word "days" was the bug. Deleting it was the fix. What remained was a number pointing at nothing in particular, which was the entire point.

## Why points exist: a disguise against pressure

Asked years later why story points were created, Ron Jeffries gave an answer about politics, not measurement: points "were invented to obfuscate duration so that certain managers would not pressure the team." The dimensionless number was a screen, and the thing it screened against is named in the sentence: managerial pressure on duration.

That pressure has a lineage. Winston W. Royce, in "Managing the Development of Large Software Systems" (Proceedings of IEEE WESCON, August 1970), drew the sequential cascade of analysis to design to code to test only to condemn it. Of the single-pass version he wrote: "I believe in this concept, but the implementation described above is risky and invites failure." His objection was late discovery, testing arriving only at the end, so that a project committed to requirements and a schedule before anyone knew whether the design worked. His remedy was iteration: do it twice, involve the customer. Industry copied the diagram and ignored the warning, because fixed-bid government and aerospace contracts needed a number to sign against.

That contractual need is real, and it predates agile. A buyer cannot countersign "we will forecast by throughput," so the commitment ritual answers a genuine problem.

What it does to a team is a different matter, and the damage runs through a three-way confusion. Steve McConnell, author of *Software Estimation: Demystifying the Black Art* (2006), separates three things teams routinely fuse: an estimate is a probabilistic prediction, a target is a business-desired date, a commitment is a promise to deliver. The pathology is collapsing all three into one number. Tom DeMarco's definition of what an estimate becomes under that pressure, quoted in McConnell, is bleaker still: an estimate is "the most optimistic prediction that has a non-zero probability of coming true," which yields "the earliest date by which you can't prove you won't be finished."

Management pressure converts the estimate into a commitment and then holds the team to it as though it were a measurement. The point was never a better unit. It was the costume agile wore so that a calendar number could not be turned back on the team as a promise it never made.

## Estimates were always going to miss

Daniel Kahneman, who shared the 2002 Nobel Prize in economics for work on judgement under uncertainty, opens chapter 23 of *Thinking, Fast and Slow* (2011) with his own failure. His team estimated about two years to finish a curriculum project. Pressed for the outside number, a senior member admitted that comparable teams had taken seven to ten years and that a sizable fraction never finished at all. The book took eight years. The people who study prediction error committed it in real time.

The miss is not carelessness. Kahneman and Tversky named it in 1979, in "Intuitive Prediction: Biases and Corrective Procedures": the planning fallacy, an optimistic bias in which people underestimate how long a task will take even when they know that similar tasks took longer. It is structural, not personal.

Its engine is the inside view. A forecast built from the specifics of this plan, this team, this feature, runs low by construction, because the specifics never include the unknown problems that have no place in a plan. The outside view ignores the particulars and reads the distribution of outcomes for similar past efforts. Roger Buehler and colleagues measured the gap in 1994 ("Exploring the 'Planning Fallacy'," *Journal of Personality and Social Psychology* 67(3)): students predicted their theses would be done in about 34 days and took about 56, and only a minority finished inside their own estimate. The result that lands hardest is the confidence study: students blew past the deadline they had called 99 percent certain, virtually guaranteed, more than half the time.

The correction has a name and a record. Bent Flyvbjerg, of Oxford's Saïd Business School, turned the outside view into a method called reference-class forecasting: predict from the outcome distribution of comparable completed projects rather than from the plan. Kahneman called it "the single most important piece of advice regarding how to increase accuracy in forecasting." Flyvbjerg's own data give the reason it is needed. The iron law of megaprojects, in his phrase, is "over budget, over time, under benefits, over and over again," with "nine out of ten such projects" running cost overruns. His 2002 study of 258 transport projects worth roughly US$90 billion (Flyvbjerg, Holm and Buhl, *Journal of the American Planning Association* 68(3)) found average cost overruns, in constant prices, of 44.7 percent for rail, 33.8 percent for bridges and tunnels, and 20.4 percent for roads, and concluded that the underestimation "cannot be explained by error and is best explained by strategic misrepresentation, that is, lying."

The trap that keeps a team on the inside view is uniqueness bias. Planners who see their project as singular conclude they have nothing to learn from anyone else's history, and Flyvbjerg's numbers show they do worse for it. The conviction that your codebase is different, your team is different, this feature is different, is not an exemption from the planning fallacy. It is the planning fallacy speaking in its own defence.

## And the fix breaks too

"When a measure becomes a target, it ceases to be a good measure." The line is everywhere, usually hung on the economist Charles Goodhart. He did not write it. The anthropologist Marilyn Strathern coined that phrasing in 1997, paraphrasing him. Goodhart's own 1975 sentence is drier and more exact: "Any observed statistical regularity will tend to collapse once pressure is placed upon it for control purposes."

Velocity is offered as the answer to the missing estimate. Measure points per sprint, average them, project forward, read off a date. As an observed regularity it is fine. The trouble begins the instant velocity stops being observed and starts being targeted, which is the precise condition Goodhart's original names: pressure placed on the regularity for control purposes.

Donald Campbell, the psychologist, sharpened the point in 1976: "The more any quantitative social indicator is used for social decision-making, the more subject it will be to corruption pressures and the more apt it will be to distort and corrupt the social processes it is intended to monitor." Campbell's law predicts more than a degraded number. It predicts that the work the number was meant to watch gets corrupted too, which is the worse failure for velocity.

The mechanism is mundane. Asked to raise velocity, a team takes the cheapest path, which is not faster delivery but point inflation: yesterday's 3 becomes today's 5, the burndown slopes down handsomely, and the cadence of shipped work does not change at all.

So there are two failures, and they are independent. Estimates miss because the inside view runs low. The velocity fix misses because a measure under control pressure corrupts the work it was counting. The burndown can trend perfectly to zero while nothing ships any sooner, and the conclusion both failures reach is the same: the point was never the thing worth measuring.

## What you were never shown: forecasting without estimates

"85% chance of done by 12 June." No planning poker session produces that sentence. The burndown hands over a single number, six sprints, a hundred and twenty points, and offers no account of how likely it is. The line with a percentage on it is a different kind of object.

The difference is in kind, not degree. Deterministic forecasting produces one number and hides the variability that makes completion a distribution rather than a point, so it is wrong by construction. Probabilistic forecasting produces a date with a confidence attached and reports the uncertainty it carries. The data needed for the second kind already sit in the team's tracker, unread in this form: throughput, the count of items finished per unit time, and cycle time, how long an item takes once it has started. Both are measured, not guessed.

The relation between them is Little's Law, in the operational form Daniel Vacanti sets out in *Actionable Agile Metrics for Predictability* (2015): average cycle time equals average work-in-progress divided by average throughput. The lever sits in plain sight: when work-in-progress is held low and stable, cycle time becomes predictable. Vacanti's own counsel is to "forget the equation and focus on the assumptions," because the law holds only while the process obeys its stability conditions. A process must be steadied before its own history can forecast its future.

Monte Carlo simulation does the forecasting. Take the historical throughput, resample it thousands of times to simulate how long the remaining items will take, and read a distribution of completion dates with confidence percentiles off the result. Troy Magennis, of Focused Objective, popularised the technique from flow data in *Forecasting and Simulating Software Development Projects* (2011); Vacanti, in *When Will It Be Done?* (2019), warns against forecasting from average throughput, which discards the very variability the method exists to capture; and Prateek Singh's back-testing in 2021 found that simply resampling historical throughput outperformed the more elaborate variants.

Item size barely predicts cycle time once work-in-progress is controlled. So counting the remaining items and dividing by historical throughput forecasts about as well as summing point estimates, at a fraction of the cost, and that is what makes estimation optional. Vasco Duarte's 2012 data across ten teams put the correlation between summed story points and plain story count at 0.755, 0.83, 0.92, 0.51, 0.88, 0.86, 0.70, 0.75, and 0.88, one weak figure among nine strong ones, and concluded that "the data above does not seem to suggest any significant advantage of using Story Points as a metric." This is one practitioner's observational data, not a controlled trial, and the 0.51 is part of the record.

The limit belongs in the same breath. Counting matches summing only when items are roughly right-sized, drawn from the same distribution as the history they are forecast against. Black Swan Farming documents the counterexample: a backlog whose items ran about three times larger than history forecast six weeks by count against sixteen by points. The condition is real, and the claim is "as well as or better than, given right-sized items," not "always better."

The forecast the team needs was never in the points. It was in the data the burndown was already throwing away.

## The objections that survive

On 2 August 2015 Steve McConnell published "17 Theses on Software Estimation," the canonical rebuttal to the movement, written by the author of *Software Estimation: Demystifying the Black Art*. Several of his theses hold their ground.

Thesis 5 lists what estimates buy: "numerous legitimate, important business purposes," among them budget allocation, cost-benefit analysis, prioritisation, financial forecasting, and progress tracking. Thesis 7 separates two things the movement sometimes runs together: "Estimation and planning are not the same thing, and you can estimate things that you can't plan." Thesis 17 states the corporate preference plainly: "Agility plus predictability is better than agility alone." And Thesis 10 cuts toward both sides at once: people conflate estimate, planning target, and commitment, so much of the heat in the argument is really about misused commitments, not about estimates as such, the same collapse DeMarco and McConnell named decades earlier.

Two pressures the forecasting argument cannot dissolve. External commitments come first: contracts, marketing launches, and regulatory deadlines all force a feasibility call that needs a time model of some kind, and "we don't estimate" is not an answer to "can we make the launch." Then coordination: when Team B depends on Team A, A's refusal to give any forecast leaves B unable to plan, and single-team flow does not, by itself, satisfy that claim.

The sharpest objection is the one to concede in full. Any decision under uncertainty rests on some model of how long things take, which means forecasting from throughput is itself an estimate, an empirical and probabilistic one. Critics who call NoEstimates "no bad up-front estimates" rebranded are describing it accurately.

Conceding it strengthens the case rather than surrendering it. Woody Zuill, who popularised the hashtag, defined it in 2013 as "exploring alternatives to estimates for making decisions in software development," exploratory by his own words, not a vow of literal silence. The target was always the bad up-front estimate, the single hopeful number committed before the work was understood, not the act of prediction. NoEstimates was never the promise to predict nothing. It is the refusal to commit to a number before the work has taught you what the number should be.

## The practice that remains

The case for dropping points rests on two failures that do not depend on each other. The inside view runs low: that is the planning fallacy, the students missing even the deadline they were 99 percent sure of. The cure is the outside view, forecasting from the distribution of past work rather than from the plan, with uniqueness bias as the trap that keeps a team from using it. And the popular software fix fails for a second, unrelated reason: a measure under control pressure collapses and corrupts what it measures, which on a sprint board is point inflation behind a healthy-looking burndown.

What remains is lighter than planning poker, and it is four things, not zero. Forecast by counting throughput: count the items finished per unit time, divide the remaining work by that rate, read the date probabilistically. Keep stories small and similar, so the count holds, within an order of magnitude of one another, which is what made counting match summing in the first place. Drop the points-to-date conversion: stop summing points into velocity and sloping a burndown toward a date, because the conversion is the step that breaks and the count does its job without it. And size only when the conversation clarifies the work rather than the number: Martin Fowler, who lent story counting its mainstream credibility in 2013, warns that counting loses the side benefit of surfacing a hidden blob of complexity, so estimate when you need to force that blob into the open or to split a story, then throw the number away.

None of this is free. Right-sizing is work. Stabilising flow before trusting its history is work. Counting is cheap only after the items have been made comparable, which is why Fowler suspected story counting was "a technique for more advanced teams." The practice that remains asks for discipline; it does not ask for the points.

You can stop estimating, in the sense the movement actually means: no bad up-front number committed before the work is understood. The work will tell you when it is done, and it will tell you sooner than the number ever did.

## Sources

- Ron Jeffries, [*Story Points Revisited*](https://ronjeffries.com/articles/019-01ff/story-points/Index.html) (23 May 2019)
- Mike Cohn, [*What Are Story Points?*](https://www.mountaingoatsoftware.com/blog/what-are-story-points)
- Mike Cohn, [*It's Effort, Not Just Complexity*](https://www.mountaingoatsoftware.com/blog/its-effort-not-complexity)
- Wikipedia, [*Planning poker*](https://en.wikipedia.org/wiki/Planning_poker)
- Wikipedia, [*Chrysler Comprehensive Compensation System*](https://en.wikipedia.org/wiki/Chrysler_Comprehensive_Compensation_System)
- Martin Fowler, [*C3*](https://martinfowler.com/bliki/C3.html)
- Winston W. Royce, [*Managing the Development of Large Software Systems*](https://www.praxisframework.org/files/royce1970.pdf) (IEEE WESCON, August 1970)
- Steve McConnell, [*Software Estimation: Demystifying the Black Art*, ch. 3](https://www.oreilly.com/library/view/software-estimation-demystifying/0735605351/ch03.html)
- Steve McConnell, [*17 Theses on Software Estimation*](https://stevemcconnell.com/17-theses-software-estimation/) (2 August 2015)
- Wikipedia, [*Planning fallacy*](https://en.wikipedia.org/wiki/Planning_fallacy)
- Roger Buehler, Dale Griffin and Michael Ross, [*Exploring the "Planning Fallacy"*](https://spsp.org/news-center/character-context-blog/planning-fallacy-inside-view) (JPSP 67(3), 1994)
- Bent Flyvbjerg, Mette Holm and Søren Buhl, [*Underestimating Costs in Public Works Projects: Error or Lie?*](https://ti.org/pdfs/Flyvbjerg02.pdf) (JAPA 68(3), 2002)
- Bent Flyvbjerg, [*The Iron Law of Megaprojects*](https://medium.com/data-science/the-iron-law-of-megaprojects-18b886590f0b)
- Wikipedia, [*Goodhart's law*](https://en.wikipedia.org/wiki/Goodhart%27s_law)
- NCBI PMC, [*Goodhart and Strathern provenance*](https://pmc.ncbi.nlm.nih.gov/articles/PMC7901608/)
- Wikipedia, [*Campbell's law*](https://en.wikipedia.org/wiki/Campbell%27s_law)
- T. Cagley, [*Actionable Agile Metrics for Predictability: Little's Law*](https://tcagley.wordpress.com/2017/11/04/actionable-agile-metrics-for-predictability-by-daniel-s-vacanti-re-read-saturday-week-4-introduction-to-littles-law/)
- T. Cagley, [*Actionable Agile Metrics for Predictability: Monte Carlo*](https://tcagley.wordpress.com/2018/02/17/actionable-agile-metrics-for-predictability-by-daniel-s-vacanti-re-read-saturday-week-17-monte-carlo-method-introduction/)
- Troy Magennis, [*Introduction to Monte Carlo Forecasting*](https://observablehq.com/@troymagennis/introduction-to-monte-carlo-forecasting)
- Vasco Duarte, [*Story Points Considered Harmful*](https://softwaredevelopmenttoday.com/2012/01/story-points-considered-harmful-or-why-the-future-of-estimation-is-really-in-our-past/) (25 January 2012)
- Martin Fowler, [*StoryCounting*](https://martinfowler.com/bliki/StoryCounting.html) (16 July 2013)
- Allen Holub, [*#NoEstimates, An Introduction*](https://holub.com/noestimates-an-introduction/)
- Woody Zuill, [*The #NoEstimates Hashtag*](https://zuill.us/WoodyZuill/2013/05/17/the-noestimates-hashtag/) (17 May 2013)
- Black Swan Farming, [*How to do a really basic forecast*](https://blackswanfarming.com/how-to-do-a-really-basic-forecast/)
