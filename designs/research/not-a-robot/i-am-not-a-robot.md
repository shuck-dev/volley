# I Am Not A Robot

---

## I. The Checkbox

The checkbox. "I am not a robot." No date, no name, no introduction. The flat machine-voice of a test only minds can pass, administered by something with no concept of mind.

Click it. The page moves on. Nobody asks what just happened: a machine, unable to know whether the clicker has a mind, has commissioned the clicker to perform the one judgement the machine cannot make and accepted the performance as proof.

The asserter problem sits inside every click. When a person checks the box, the claim is at least coherent: a human attesting to being human. When a language model checks it, the claim loops back on itself. When a researcher asks whether a field has made progress on mind, the claim dissolves entirely: progress toward what, as measured by what, as decided by whom?

That question is not new. It is the question **Alan Turing** answered, in 1950, by deciding it was unanswerable. "The original question, 'Can machines think?' I believe to be too meaningless to deserve discussion." [\[1\]](#ref-1) He did not flinch from the question; he looked at it squarely and replaced it with something measurable. The imitation game. Could a machine's text output fool a human judge into thinking it was a person? That was testable. The other question was not.

His move was deliberate and reasoned. He was not evading; he was engineering. The trouble is that the engineering step buried the original question rather than closing it. Every benchmark that followed inherited the same structure: a measurable proxy for an undefined target, built on a declared agnosticism about what the target was. The checkbox is the imitation game's consumer edition. Same architecture. A billion daily administrations of the same unresolved bet.

The proxy for the question and the question itself have been running in parallel ever since. One of them ships product. The other does not stop.

---

## II. The Mailbox and the Reasonable Answer

I built a message channel for the sub-agents in Volley's development tooling. Nothing exotic: a shared structure where one agent could leave a note, flag a conflict, ask a clarifying question before doing the wrong thing in the wrong file. I ran an experiment. I gave them the channel and watched. They did not use it. An agent would complete its slice, produce output, and stop. The next agent would pick up the output and proceed. No questions. No flags. The plumbing was working. The signal was absent.

I iterated. I wrapped the channel in clearer affordances, surfaced it earlier in the context window, added a step in the brief that named the channel explicitly. Each fix worked, in the sense that agents used the channel after I made it harder to ignore. What I could not find was the unprompted reaching out: one agent noticing something uncertain and deciding, on its own, that the right move was to ask. The behaviour required continuous forcing. Remove the force, lose the behaviour.

The sensible answer is capability. More compute, more data, richer feedback loops: the bet is that the gap closes. There is genuine empirical support for that family of bets. Language models have improved on tasks that looked impossible five years ago. Give the argument its strongest form: systems complex enough to model a collaborator's uncertainty, in context rich enough to use that model, may reach for the channel without being pushed. The trajectory suggests this is not obviously impossible.

But the argument requires a defined target. "Intelligence" is doing load-bearing work in the phrase "closes the intelligence gap", and the labs sell a schedule without defining what the schedule is toward. There is no agreed target, no agreed measurement, and the absence is not a technical problem awaiting resolution: it is the original question, renamed and left open. Turing refused to define it in 1950. Every benchmark since has measured a proxy. And the agent does not reach for the channel. Humans communicate because it serves them: they model the other mind, weight the cost of a wrong action against the cost of a brief pause, and reach out when the arithmetic favours it. That is a self-interested instinct, shaped by social stakes, running below deliberate choice. Infrastructure cannot manufacture it. A channel can be made more visible, a prompt can name it, a brief can require it, and the agent will comply. But compliance is not the instinct arising. The channel sat unused until I made it impossible to ignore, and that is not a hardware limitation that will yield to more parameters.

The word "intelligence" was borrowed from ordinary language and put to work without being cleaned. What is it, exactly, that scale is supposed to close?

---

## III. The Missing Channels

The gap is not in the training run. The gap is in the signal.

There is a radio telescope problem in signal processing that engineers know well. You can increase the gain on a receiver indefinitely, but if the source never transmitted on a given frequency, no amount of amplification recovers the signal. Resolution cannot be raised on a channel that was never sampled.

Consider three channels that were never sampled. The feel of a muscle past its limit: not the word "exhaustion," not adjacent tokens about effort and collapse, but the proprioceptive fact, arriving in the body before the mind has named it. The weight of a choice that cannot be undone: the specific quality of the moment after, when the available futures narrow and the narrowing is felt as a physical constriction in the chest. The social cost of being wrong in front of someone who matters: not embarrassment as a label, but the flush and the altered posture and the recalibration of standing that arrives before any word is out. These are not absent tokens. They are absent signal.

This is not a new observation. It has the shape of a very old problem, one that the discipline best positioned to handle it quietly passed to another field, which passed it back.

In 1687, Isaac Newton published the *Principia Mathematica* as a work of natural philosophy. When William Whewell coined the word "scientist" in 1833, what followed was a sorting: the new sciences took the questions they could answer and left behind the ones they could not measure. Almost all of it transferred. One question did not. The question of mind sat at the border and watched the sciences depart.

Thomas Nagel located the structural reason in 1974. His paper in *The Philosophical Review* opened with a sentence that has not been improved on: "An organism has conscious mental states if and only if there is something that it is like to be that organism, something it is like *for* the organism." [\[2\]](#ref-2) The bat thought experiment follows from that sentence directly. No accumulation of third-person description of bat echolocation tells you what it is like to perceive through echolocation. You can describe the frequency range, the neural processing, the flight path corrections. The description gets richer and richer. It does not get closer to the experience, because it is not failing at the same task; it is succeeding at a different task. The gap is not between thin description and rich description. It is between description and experience. More description does not close a categorical gap.

David Chalmers gave the categorical gap its architecture in 1995. He distinguished the easy problems of consciousness, tractable by the standard methods of mechanistic explanation, from the hard problem: explaining why any physical or functional process gives rise to subjective experience at all. "Even after we have explained the performance of all the cognitive and behavioural functions in the vicinity of experience," he wrote, "there may still remain a further question: why is the performance of these functions accompanied by experience?" [\[3\]](#ref-3) A philosophical zombie, a physical duplicate of a person functionally identical in every respect, is conceivable without consciousness. If that is coherent, then phenomenal experience is not a functional property. Functional completeness, at any scale, cannot guarantee phenomenal closure. The engineering posture that treats capability as the target and scale as the path never addresses this assumption. It inherits the hard problem without acknowledgement.

Western philosophy eventually came back around. Maurice Merleau-Ponty, writing in 1945, argued that mind is constituted through sensorimotor coupling with the world, not separable from the body that enacts it. [\[4\]](#ref-4) That argument reopened a question the Cartesian lineage had spent three centuries closing off. Classical Chinese philosophy never closed it. In the tradition centred on *xin*, the heart-mind, thinking, knowing, intention, emotion, and desire were aspects of a single process, inseparable from the *qi* that constitutes both somatic dynamics and the motivating force of thought. Roger Ames' formulation is "bodyheartminding": one word, because the separation that would require three was not made. [\[5\]](#ref-5) This is convergence, not correction: a different lineage arriving at embodied integration as the baseline rather than the recovery.

The unified, bounded Western self, the thing a Cartesian splits from the body and an analytic philosopher of mind tries to locate, is one answer to the question of what mind is. It is a contingent answer. It is not the universal frame. The Upanishadic traditions of early Indian philosophy held that the self, *Atman*, was not bounded at all: the individual self and the ground of all being, *Brahman*, were identical, not two things but one seen from two angles. Buddhist philosophy, emerging partly as a direct refutation of that claim, argued that there was no stable self to identify with anything: *anatta*, no-self, a deliberate denial that there is a persisting entity behind the flux of experience. These are not casual positions. They are sophisticated, argued disagreements, separated by centuries of rigorous debate, arrived at by thinkers who had considered the question carefully and landed in opposite places. The question of what the self is was a live intellectual contest long before Descartes drew his line, and outside the tradition he was working in. The Western analytic frame that treats mind as a bounded, separable thing whose capacities can be measured on a scale did not inherit a settled answer. It inherited one contested position and built an industry on the assumption that the contest was closed.

The engineering tradition started from the post-Cartesian position and built forward, assuming the question had been answered or could be deferred. The channels that carry proprioception, mortality, and social stakes were never sampled. The gap arrived at the training data, unnamed and intact.

None of this would matter if the labs named the gap honestly and built toward it with calibrated uncertainty. They do not.

---

## IV. The Confident Unknown

The labs know the gap exists. They have a name for it. The name does not close the gap.

**Turing** made a founding decision in 1950, not an oversight. He called "Can machines think?" "too meaningless to deserve discussion" and replaced it with a behavioural proxy: can the machine fool a person into thinking it is human? The checkbox is his grandchild. Every benchmark that came after is another generation of the same substitution: measurable output standing in for an undefined target.

The substitution compounds. MMLU launched as the flagship test of broad general knowledge, the thing language models were supposed to be learning. GPT-3 scored roughly 35%. That felt like progress had a ladder. Frontier models now score between 88% and 90%, within measurement noise of each other, crowded at the ceiling. What the saturation tells you is not that the problem is solved. It tells you the proxy diverged from the target before anyone agreed what the target was, and that the labs kept climbing the proxy anyway. Benchmark practices are, as a 2025 interdisciplinary review put it, "normative instruments that perpetuate particular epistemological perspectives about how the world is ordered." [\[6\]](#ref-6) A 2024 study in the same vein noted that "cultural AI benchmarks often rely on implicit assumptions about measured constructs, leading to vague formulations with poor validity and unclear interrelations." [\[7\]](#ref-7) The benchmarks were not neutral tape measures. They were built by people with particular assumptions about what a mind does, and those assumptions were baked in as fact.

The Chinese Room named the category error: syntax is not semantics, correct output does not entail understanding. Benchmark failures are not the same mechanism; distribution shift, data contamination, and Goodhart pressures each do their own work. But the underlying move is identical. The evidence keeps accumulating. One preprint from November 2025 documented a system performing at 60% on a single-run evaluation and 25% across eight consecutive runs on the same task. [\[8\]](#ref-8) The same system, the same task; the variance alone swallows the headline number.

The training regime compounds the problem from the inside. Zhou et al. found that "reward models used in PPO exhibit inherent biases towards high-confidence scores regardless of the actual quality of responses." [\[9\]](#ref-9) The training dynamic that makes a model sound certain is the house style of the institutions that built it. RLHF does not optimise for calibrated uncertainty; it optimises for responses that annotators prefer, and annotators prefer confident-sounding output. What gets deployed is the model that sounds most confident, and calibration is what got cut.

**Hume** arrived at this problem in 1739, working by introspection alone. "I never can catch myself at any time without a perception, and can never observe any thing but the perception." [\[10\]](#ref-10) No stable knower behind the knowing; only a succession of impressions the imagination weaves into an illusion of unity. The mechanistic receipt earned in the two centuries since is exact: when a model is asked how confident it is, the score it returns was trained to sound calibrated, not to be calibrated. There is no self-model behind the self-report, no introspective access to underlying uncertainty, only a surface-level pattern selected for by the reward signal. Hume's bundle, restated as a training artifact.

The question of who defines the target has an answer: whoever raised the last round.

In January 2025, Sam Altman wrote on his personal blog: **"We are now confident we know how to build AGI as we have traditionally understood it."** Note the clause doing the work: "as we have traditionally understood it." Altman is not claiming to have defined AGI; he is claiming to have met a definition already in circulation. What definition, whose, on what evidence: the post does not say. [\[11\]](#ref-11) In April 2025, Demis Hassabis told CBS News: "In the next five to ten years, I think." The context was "a system that really understands everything around you in very nuanced and deep ways," which Hassabis described as a capability threshold, not strict AGI. [\[12\]](#ref-12) A month later, speaking to Axios, Hassabis placed AGI "just after 2030" and acknowledged needing "a couple more big breakthroughs"; Sergey Brin, in the same conversation, said "just before 2030." [\[13\]](#ref-13) The breakthroughs are unnamed. The dates are specific. The target is not.

Three named people. Three dates in the next decade. One undefined target. The dates are confident. The target is the thing Turing refused to define.

The confusion is not accidental. A confident schedule raises a round; a calibrated unknown does not. The labs are not lying; they are operating inside a frame where the confusion between the proxy and the target is built into the financial architecture. Every benchmark, every RLHF reward signal, every round announcement optimises for the thing that can be measured and funded, while the thing being measured remains undefined. That is not a recent failure of rigor. That is the founding decision, Turing's 1950 substitution, intact.

I am not arguing the risk is zero. I am arguing the schedule is fiction.

---

## V. Clarification, Not Panic

The schedule is fiction. That is a different claim from saying the destination does not exist.

This essay is not saying the risk is manageable. A decade is enough time for a surprise that changes the whole argument. A better training mechanism, a different architecture, a convergence nobody saw coming: any of these could land the question before the generation is out. I might be wrong. The plateau Ilya Sutskever named in December 2024, standing in front of the audience that built the scaling era with him, might break.

The confident schedule is not supported by the state of the question. The specific mechanism that carried the last decade of capability gains is acknowledged, by the people who built it, as hitting its ceiling. The pivot to test-time compute and synthetic data might close the remaining distance. It might not. A March 2025 AAAI survey of 475 AI researchers found 76% said scaling current LLMs alone was unlikely or very unlikely to reach AGI. [\[14\]](#ref-14) The argument for a near-term arrival is weaker than the marketing suggests, and the people who know the engineering best are the ones who say it aloud.

The labs borrowed the oldest question in philosophy, renamed it, and started billing for the answer on a schedule, without owning the gap between their stated target and the question they are actually approaching. That gap is not an honest unknown. A confident arrival date raises a round; a calibrated uncertainty does not.

The ask is not that they slow down. It is that they say what they mean by what they are building, and hold the definition stable enough to be evaluated by people outside the room. The honesty the labs owe to the public is the same honesty this essay owes its reader: name what you know, name what you do not, and stop performing certainty you have not earned.

I clicked a box to prove I was not a machine, and that was enough. The checkpoint was not a test of what I am. It was a test of what I could do. Turing said the question was too meaningless to deserve a definition. The labs have built a two-trillion-dollar industry on the same evasion, and called it progress.

---

## References

<a name="ref-1"></a>\[1\] Turing, A. M. "Computing Machinery and Intelligence." *Mind*, 59(236), 433-460 (1950). https://doi.org/10.1093/mind/LIX.236.433

<a name="ref-2"></a>\[2\] Nagel, T. "What Is It Like to Be a Bat?" *The Philosophical Review*, 83(4), 435-450 (1974). https://doi.org/10.2307/2183914

<a name="ref-3"></a>\[3\] Chalmers, D. "Facing Up to the Problem of Consciousness." *Journal of Consciousness Studies*, 2(3), 200-219 (1995). https://consc.net/papers/facing.html

<a name="ref-4"></a>\[4\] Merleau-Ponty, M. *Phenomenology of Perception* (1945). English translation: Routledge, 2002.

<a name="ref-5"></a>\[5\] Ames, R. T. *Confucian Role Ethics: A Vocabulary* (2011). University of Hawaii Press. See also Slingerland, E. *Mind and Body in Early China* (2019). Oxford University Press.

<a name="ref-6"></a>\[6\] Eriksson, M., et al. "Can We Trust AI Benchmarks? An Interdisciplinary Review of Current Issues in AI Evaluation." arXiv:2502.06559 (2025). https://arxiv.org/abs/2502.06559

<a name="ref-7"></a>\[7\] Rystrøm, J. H., and Enevoldsen, K. C. "Exposing Assumptions in AI Benchmarks through Cognitive Modelling." arXiv:2409.16849 (2024). https://arxiv.org/abs/2409.16849

<a name="ref-8"></a>\[8\] Mehta, S. "Beyond Accuracy: A Multi-Dimensional Framework for Evaluating Enterprise Agentic AI Systems." arXiv:2511.14136 (submitted 18 November 2025). https://arxiv.org/abs/2511.14136

<a name="ref-9"></a>\[9\] Leng, J., et al. "Taming Overconfidence in LLMs: Reward Calibration in RLHF." arXiv:2410.09724 (2024). https://arxiv.org/abs/2410.09724

<a name="ref-10"></a>\[10\] Hume, D. *A Treatise of Human Nature* (1739), Book I, Part IV, Section VI.

<a name="ref-11"></a>\[11\] Altman, S. "Reflections." Personal blog, January 2025. https://blog.samaltman.com/reflections

<a name="ref-12"></a>\[12\] Hassabis, D. Interview with CBS News *60 Minutes*, broadcast April 20, 2025. https://www.cbsnews.com/news/artificial-intelligence-google-deepmind-ceo-demis-hassabis-60-minutes-transcript/

<a name="ref-13"></a>\[13\] Hassabis, D. and Brin, S. Interview with Axios, May 21, 2025. https://www.axios.com/2025/05/21/google-sergey-brin-demis-hassabis-agi-2030

<a name="ref-14"></a>\[14\] AAAI Presidential Panel on the Future of AI Research. Survey of 475 AI researchers, March 2025. https://aaai.org/wp-content/uploads/2025/03/AAAI-2025-PresPanel-Report-Digital-3.7.25.pdf
