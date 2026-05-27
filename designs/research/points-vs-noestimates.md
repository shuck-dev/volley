# Estimating Without Estimates

Research compiled 2026-05-27.

## The ritual every sprint repeats

James Grenning named Planning Poker in 2002, after a meeting where two senior engineers dominated and six others sat out. Turning the cards over at once strips out anchoring and seniority, so the number that lands is the team's, not the loudest voice's. The cards skip 4, 6, and 7, the widening Fibonacci gaps forcing a decisive bucket instead of a haggle over six versus seven.

Those points, summed and averaged each sprint, become velocity, and velocity slopes the burndown toward a date the team plans against and trusts, because it comes from the team's own output rather than a manager's wish. And yet almost no one at the table, asked what a point measures, can answer. The foundation under it has never been read.

## How a unit of time became a unit of nothing

March 1996. The Chrysler Comprehensive Compensation System, a Smalltalk payroll replacement, had not yet printed a single paycheck. Kent Beck, the originator of Extreme Programming, became project leader that month and brought Ron Jeffries onto the team, and the unit of estimation now used by teams who have never heard of Chrysler was born here.

It began with a name that meant something. Jeffries, who built Extreme Programming alongside Beck and Ward Cunningham, recalls in *Story Points Revisited* (23 May 2019) that stories were sized in "Ideal Days," which he glosses as "how long it would take a pair to do it if the bastards would just leave you alone." The name said what it counted: days.

Reality declined to cooperate. "We multiplied Ideal Days by a 'load factor' to convert to actual implementation time," Jeffries writes. "Load factor tended to be about three: three real days to get an Ideal Day's work done." The unit did not break in the code. It broke in the conversation with stakeholders, who "were often confused by how it could keep taking three days to get a day's work done."

The fix was a deletion. "We started calling our 'ideal days' just 'points'," Jeffries writes, so a three-point story would take about nine days. Removing the word "days" removed the promise embedded in it, that one estimated day would be one calendar day, and left the conversion to calendar time to be supplied later by velocity. The word "days" was the bug, and deleting it was the fix. What remained was a number that pointed at nothing.

## Why points exist: a disguise against pressure

Asked years later why story points were created, Jeffries gave an answer about politics, not measurement: they were "originally invented to obscure the time aspect, so that management wouldn't be tempted to misuse the estimates." The dimensionless number was a screen against a manager turning a time estimate into a deadline.

That pressure predates agile. Winston Royce sketched the waterfall in 1970 only to call it "risky" and warn it "invites failure," yet industry copied the diagram and ignored the warning, because fixed-bid government contracts needed a number to sign against. That contractual need is real: a buyer cannot countersign "we will forecast by throughput," so the commitment ritual answered a genuine problem.

The damage runs through a three-way confusion. Steve McConnell, author of *Software Estimation: Demystifying the Black Art* (2006), separates three things teams fuse: an estimate is a probabilistic prediction, a target is a business-desired date, a commitment is a promise to deliver. The pathology is collapsing all three into one number, which Tom DeMarco, quoted in McConnell, defined as "the most optimistic prediction that has a non-zero probability of coming true." Management pressure converts that estimate into a commitment and holds the team to it as though it were a measurement. The point was the costume agile wore so a calendar number could not be turned back on the team as a promise it never made.

## Estimates were always going to miss

Estimation fails twice over, and the two failures are independent. The first is in the estimator's head. Daniel Kahneman, who won a Nobel for his work on judgement under uncertainty, opens chapter 23 of *Thinking, Fast and Slow* (2011) with his own: his team estimated about two years to finish a curriculum project, a senior member admitted comparable teams had taken seven to ten years and that many never finished, and the book took eight. The people who study prediction error committed it in real time.

The miss is not carelessness. Kahneman and Tversky named it in 1979: the planning fallacy, an optimistic bias in which people underestimate how long a task will take even when they know that similar tasks took longer. Its engine is the inside view, a forecast built from the specifics of this plan, this team, this feature, which runs low by construction because the specifics never include the unknown problems that have no place in a plan. The outside view ignores the particulars and reads the distribution of outcomes for similar past efforts. Roger Buehler and colleagues measured the gap in 1994: students predicted their theses would be done in about 34 days and took about 56, and they blew past even the deadline they had called 99 percent certain more than half the time.

The correction has a name and a record. Bent Flyvbjerg, of Oxford's Saïd Business School, turned the outside view into reference-class forecasting: predict from the outcome distribution of comparable completed projects rather than from the plan. Kahneman called it "the single most important piece of advice regarding how to increase accuracy in forecasting." Flyvbjerg's data say why it is needed: his iron law of megaprojects is "over budget, over time, under benefits, over and over again," with nine of ten running cost overruns, and his study of 258 transport projects concluded the underestimation "cannot be explained by error and is best explained by strategic misrepresentation, that is, lying."

The trap that keeps a team on the inside view is uniqueness bias. Planners who see their project as singular conclude they have nothing to learn from anyone else's history, and Flyvbjerg's numbers show they do worse for it. The conviction that your codebase is different, your team is different, this feature is different is not an exemption from the planning fallacy. It is the planning fallacy speaking in its own defence.

## And the fix breaks too

The second failure is in the fix. The proponents have a real answer to the planning fallacy: a point was never a unit of time. Mike Cohn, who wrote *Agile Estimating and Planning* and co-founded the Scrum and Agile Alliances, argues that points measure relative effort rather than hours, and that velocity converts them to a date empirically, from the team's own delivered output. Refuse to pin a point to a fixed number of hours and the estimate stays honest. The answer holds until you look at the converter.

"When a measure becomes a target, it ceases to be a good measure." The line is everywhere, usually hung on the economist Charles Goodhart, who did not write it; the anthropologist Marilyn Strathern coined that phrasing in 1997. Goodhart's own 1975 sentence is drier: "Any observed statistical regularity will tend to collapse once pressure is placed upon it for control purposes." Velocity is the converter Cohn relies on, and as an observed regularity it works. The trouble begins the instant it stops being observed and starts being targeted.

Donald Campbell, the psychologist, made the sharper point in 1976: a quantitative indicator used for decisions does not just degrade, it corrupts the process it was meant to monitor. Asked to raise velocity, a team takes the cheapest path, which is not faster delivery but point inflation: yesterday's 3 becomes today's 5, the burndown slopes down handsomely, and the cadence of shipped work does not change. Both failures land, and they are independent. Estimates miss because the inside view runs low; the velocity fix misses because a targeted measure corrupts the work it was counting. The burndown can trend perfectly to zero while nothing ships sooner.

## Where NoEstimates came from

The pushback had a hashtag before it had a name. In February 2010 the developer Aslak Hellesøy posted that cycle time was a richer metric than velocity and tagged it #noestimates; two years later Woody Zuill, the agile coach who originated mob programming, made the tag a movement, defining it as "exploring alternatives to estimates for making decisions in software development." The framing was exploratory, not a vow of silence.

The empirical case arrived alongside it. In January 2012 Vasco Duarte, who would later write the book *NoEstimates* (2016), posted "Story Points Considered Harmful," arguing from his teams' own data that counting stories forecast as well as summing their points. Martin Fowler, one of the Agile Manifesto's authors, named the practice story counting in 2013 and lent it mainstream credibility, crediting Josh Kerievsky of Industrial Logic with the idea.

The blunt statement of the why is Allen Holub's. The software architect and longtime writer on design puts it flatly: "Estimates are always inaccurate, usually wildly so," because "in software, you don't know what you're building or how you'll build it when you start the project." An up-front number is a guess about work nobody has seen yet, and holding a team to it, he argues, "burns people out" and leaves them not agile "in any real sense of the word."

The most telling convert is the man who built the practice the movement rejects. Jeffries disowned his own invention: "I may have invented story points, and if I did, I'm sorry now." His alternative is to slice stories small enough to finish in a day, which makes estimating them moot. The unit's inventor and its loudest critics had arrived at the same place.

## What you were never shown: forecasting without estimates

"85% chance of done by 12 June." No planning poker session produces that sentence. The burndown hands over a single number, six sprints, a hundred and twenty points, with no account of how likely it is. The line with a percentage on it is a different kind of object.

Deterministic forecasting produces one number and hides the variability that makes completion a distribution rather than a point, so it is wrong by construction. Probabilistic forecasting produces a date with a confidence attached, and the data it needs already sit in the team's tracker: throughput, the count of items finished per unit time, and cycle time, how long an item takes once it has started. The relation between them is Little's Law, which Daniel Vacanti, a co-author of the Kanban Guide, states operationally in *Actionable Agile Metrics for Predictability* (2015): average cycle time equals average work-in-progress divided by average throughput. Hold work-in-progress low and stable and cycle time becomes predictable, though only while the process is stable enough to obey the law.

Monte Carlo simulation does the forecasting: take the historical throughput, resample it thousands of times to simulate how long the remaining items will take, and read a distribution of completion dates off the result. Troy Magennis popularised the technique from flow data in 2011, and Prateek Singh's back-testing in 2021 found that simply resampling historical throughput outperformed the more elaborate variants.

Item size barely predicts cycle time once work-in-progress is controlled, so counting the remaining items and dividing by historical throughput forecasts about as well as summing point estimates, at a fraction of the cost. That is what makes estimation optional. Duarte's data across ten teams put the correlation between summed points and plain story count between 0.70 and 0.92 on nine of them, with a single 0.51 outlier, and concluded that "the data above does not seem to suggest any significant advantage of using Story Points as a metric." This is one practitioner's observational data, not a controlled trial.

The clearest case on record is Siemens Health Services. Around 2012 its fifteen Scrum teams, roughly five hundred people, dropped story points and velocity for flow metrics, and reported in an Agile Alliance experience report that their 85th-percentile cycle time fell from 71 days to 43 and then to 40, first-pass yield rose from 75 to 95 percent, and a release shipped on schedule and more than 10 percent under budget. The caveats sit in the same breath: the report came from people who built careers on flow metrics, Vacanti among them, and dropping points was bundled inside a wider move to Kanban, so the gains cannot be pinned on the estimation change alone. It is the best-documented single case, not a general law.

That single case carries one more limit. Counting matches summing only when items are roughly right-sized, drawn from the same distribution as the history they are forecast against. Black Swan Farming documents the counterexample: a backlog whose items ran about three times larger than history forecast six weeks by count against sixteen by points. The claim is "as well as or better than, given right-sized items," not "always better." The forecast the team needs was never in the points. It was in the data the burndown was already throwing away.

## The objections that survive

On 2 August 2015 Steve McConnell published "17 Theses on Software Estimation," a point-by-point defence of estimation, and several theses hold their ground. Estimates serve "numerous legitimate, important business purposes": budget allocation, prioritisation, financial forecasting. Estimation and planning "are not the same thing, and you can estimate things that you can't plan." And much of the heat is really about misused commitments, not estimates as such, the same collapse DeMarco and McConnell named decades earlier.

Then the practical pressures. External commitments come first: contracts, marketing launches, and regulatory deadlines force a feasibility call that needs a time model, and "we don't estimate" is not an answer to "can we make the launch." Coordination follows: when Team B depends on Team A, A's refusal to give any forecast leaves B unable to plan. And throughput forecasting is parasitic on history, so a new team, a new product, or genuinely novel work has no past to resample, and the pre-backlog question, whether to fund an initiative at all, arrives before there is anything to count. Here the honest move is to admit that Flyvbjerg's reference-class forecasting, the outside view this essay leans on, is itself a disciplined up-front estimate, made from comparable finished projects precisely because this one has no history yet.

The Goodhart logic that broke velocity does not spare flow metrics either. Tell a team to raise throughput and it will split tickets; tell it to hit the 85th-percentile date and quality erodes. No measure survives being made a target. The lesson was never that one metric beats another; it is to measure without targeting.

So the sharpest objection has to be conceded in full. Any decision under uncertainty rests on some model of how long things take, so forecasting from throughput is itself an estimate, an empirical and probabilistic one, and critics who call NoEstimates "no bad up-front estimates" rebranded are describing it accurately. That is the point, not a retreat from it. Zuill's "exploring alternatives" was never a vow of silence; the target was always the bad up-front estimate, the single hopeful number committed before the work was understood. NoEstimates is the refusal to commit to a number before the work has taught you what the number should be.

## Where it stands now

The hashtag faded; the practice did not. In November 2020 the Scrum Guide dropped the words "estimate" and "estimation" altogether and replaced them with "sizing," which Scrum.org says a team can satisfy by "counting cards or using flow-based metrics." The largest agile framework had removed prescribed estimation from its own definition without once crediting the movement that spent a decade arguing for it.

The people regrouped. The energy that lived on Twitter under #NoEstimates moved into a curriculum, as Vacanti and Singh built ProKanban.org and a certification track around flow metrics rather than points. The Monte Carlo forecast that once meant writing your own spreadsheet became a one-click app for Jira and Azure DevOps, a commodity layer sold by a handful of specialist vendors.

What never arrived was the evidence. In a 2024 survey of what is actually known about software effort estimation, the software-engineering writer Derek Jones found most of the field's research built on "miniscule datasets," and reported that estimation accuracy does not improve with practice, story points included. The method won adoption while the question that started the fight, whether an up-front estimate is ever worth making, was never funded well enough to answer. The practice spread on argument and experience, not proof.

## The practice that remains

What remains is lighter than planning poker, and it is four things, not zero. Forecast by counting throughput: divide the remaining items by the rate the team finishes them, and read the date probabilistically. Keep stories small and similar, within an order of magnitude of one another, so the count holds. Drop the points-to-date conversion, because the conversion is the step that breaks and the count does its job without it. And size only when the conversation clarifies the work rather than the number: Fowler warns that counting loses the side benefit of surfacing a hidden blob of complexity, so estimate to force that blob open or to split a story, then throw the number away.

None of this is free. Right-sizing is work, and stabilising flow before trusting its history is work; counting is cheap only after the items have been made comparable, which is why Fowler suspected story counting was "a technique for more advanced teams." The practice that remains asks for discipline, not for points.

You can stop estimating, in the sense the movement actually means: no bad up-front number committed before the work is understood. The work will tell you when it is done, and it will tell you sooner than the number ever did.

## Sources

- Ron Jeffries, [*Story Points Revisited*](https://ronjeffries.com/articles/019-01ff/story-points/Index.html) (23 May 2019)
- Ron Jeffries, [*Estimation is Evil*](https://ronjeffries.com/articles/021-01ff/estimation-is-evil/) (1 February 2013)
- Mike Cohn, [*Agile Estimating and Planning*](https://www.mountaingoatsoftware.com/books/agile-estimating-and-planning)
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
- Wikipedia, [*Campbell's law*](https://en.wikipedia.org/wiki/Campbell's_law)
- T. Cagley, [*Actionable Agile Metrics for Predictability: Little's Law*](https://tcagley.wordpress.com/2017/11/04/actionable-agile-metrics-for-predictability-by-daniel-s-vacanti-re-read-saturday-week-4-introduction-to-littles-law/)
- T. Cagley, [*Actionable Agile Metrics for Predictability: Monte Carlo*](https://tcagley.wordpress.com/2018/02/17/actionable-agile-metrics-for-predictability-by-daniel-s-vacanti-re-read-saturday-week-17-monte-carlo-method-introduction/)
- Troy Magennis, [*Introduction to Monte Carlo Forecasting*](https://observablehq.com/@troymagennis/introduction-to-monte-carlo-forecasting)
- Vasco Duarte, [*Story Points Considered Harmful*](https://softwaredevelopmenttoday.com/2012/01/story-points-considered-harmful-or-why-the-future-of-estimation-is-really-in-our-past/) (25 January 2012)
- Martin Fowler, [*StoryCounting*](https://martinfowler.com/bliki/StoryCounting.html) (16 July 2013)
- Allen Holub, [*#NoEstimates, An Introduction*](https://holub.com/noestimates-an-introduction/)
- Woody Zuill, [*The #NoEstimates Hashtag*](https://zuill.us/WoodyZuill/2013/05/17/the-noestimates-hashtag/) (17 May 2013)
- Black Swan Farming, [*How to do a really basic forecast*](https://blackswanfarming.com/how-to-do-a-really-basic-forecast/)
- Scrum.org, [*Why Was Estimation Replaced by Sizing in Scrum Guide 2020*](https://www.scrum.org/resources/blog/yds-why-was-estimation-replaced-sizing-scrum-guide-2020) (November 2020)
- [*ProKanban.org*](https://www.prokanban.org/)
- Derek Jones, [*What is known about software effort estimation in 2024*](https://shape-of-code.com/2024/03/10/what-is-known-about-software-effort-estimation-in-2024/) (10 March 2024)
- Daniel Vacanti and Bennet Vallet, [*Actionable Metrics at Siemens Health Services*](https://agilealliance.org/resources/experience-reports/actionable-metrics-siemens-health-services/) (Agile Alliance experience report, 2014)
