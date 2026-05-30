# I Am Not A Robot

---

## I. The Checkbox

In 1950 Alan Turing was asked whether machines can think, and he refused the question. "The original question, 'Can machines think?' I believe to be too meaningless to deserve discussion." [\[1\]](#ref-1) He did not answer it and he did not dismiss it as foolish. He judged it unanswerable as posed, because "machine" and "think" had no definitions he could test, and he replaced it with one that could be tested: could a machine's typed answers fool a human judge into taking it for a person. The imitation game measures behaviour. Whether the machine thinks, in any sense the original question meant, it leaves untouched.

That substitution was deliberate and reasoned. It was also the founding move of the field, and it set a pattern every benchmark since has followed: a measurable proxy standing in for a target nobody had defined. The checkbox labelled "I am not a robot" is the same move at consumer scale, a billion times a day, a machine that cannot know whether anyone has a mind commissioning each person to perform the one judgement it cannot make, and accepting the performance as proof.

When a person ticks the box, the claim is at least coherent: a human attesting to being human. When a language model ticks it, the claim loops back on itself. When a lab announces progress toward machine intelligence, the claim dissolves, because progress is being measured toward a target no one has agreed: progress toward what, measured how, decided by whom.

The proxy for the question and the question itself have been running in parallel ever since. One of them ships product. The other does not go away.

---

## II. The Mailbox and the Reasonable Answer

I built a message channel for a set of AI sub-agents working together on a software project. Nothing exotic: a shared place where one agent could leave a note, flag a conflict, ask a clarifying question before doing the wrong thing in the wrong file. The agents had the channel and did not use it. Each finished its slice, produced its output, and stopped. The next picked up that output and carried on, asking nothing, flagging nothing. The plumbing worked. The thing the plumbing was for never arrived.

I iterated. Clearer affordances, the channel surfaced earlier in the context, a step in the brief that named it outright. Each change worked in the narrow sense: the agents used the channel once it was harder to ignore than to skip. What never appeared was the unprompted reach, one agent noticing something uncertain and deciding, on its own, that the right move was to ask. The behaviour held only while I forced it. Remove the force, lose the behaviour.

The reasonable answer is capability. More compute, more data, richer feedback, and the gap closes. The bet has a real record behind it; models do things now that looked impossible five years ago. Put the argument at its strongest: a system rich enough to model a collaborator's uncertainty, in a context rich enough to act on the model, might reach for the channel unprompted. Nothing I saw proves that impossible.

But a person reaches for the channel because it serves them. They weigh a thirty-second question against the cost of getting it wrong in front of someone whose opinion matters, and the weighing is driven by stakes they actually carry. The agent carries none. A channel can be made visible, a prompt can name it, a brief can require it, and the agent complies, and compliance is the behaviour without the thing underneath it. What the channel kept exposing was not a shortfall of capability but the absence of a motive, and a motive is not a parameter you add.

The word "intelligence" was borrowed from ordinary language and put to work without being cleaned. What is it, exactly, that scale is supposed to close?

---

## III. The Missing Channels

The gap is not in the size of the model. It is in the kind of signal the model was trained on, and a kind that was never present cannot be recovered by adding more of what was.

Three things a person knows are carried on channels a text corpus never sampled. The feel of a muscle past its limit, the proprioceptive fact arriving in the body before any word for it. The weight of a choice that cannot be undone, the available futures narrowing and the narrowing felt as pressure in the chest. The cost of being wrong in front of someone who matters, the flush and the shift in posture that land before a sentence is formed. A corpus holds the words "exhaustion," "regret," "shame," and the words are not the signal. They are descriptions of it, written from inside bodies that had it. Train on the descriptions and you get a model of how the words pattern, which is a different thing from the channel the words point at. Adding image and audio does not close this; a system can take in a photograph of a runner and still have no purchase on what the muscle feels. This is a difference in kind, not in quantity.

The difference in kind is the oldest unsolved problem there is, handed between disciplines that each declined to keep it. In 1687 Isaac Newton published the *Principia* as natural philosophy; there were no scientists yet, only natural philosophers. William Whewell coined the word "scientist" in 1833, and the decades around it sorted the inquiry: the new sciences took the questions they could measure and left the rest. Almost everything transferred. The question of mind sat at the border and watched the sciences leave.

Thomas Nagel named why it could not follow. In 1974, in *The Philosophical Review*: "An organism has conscious mental states if and only if there is something that it is like to be that organism, something it is like *for* the organism." [\[2\]](#ref-2) You can describe a bat's echolocation completely, the frequencies, the neural wiring, the corrections in flight, and the description never approaches what it is like to perceive that way, because it is not a thinner version of the same thing. It is a different thing. More description does not converge on experience; it gets better at description. David Chalmers gave the gap its architecture in 1995, separating the easy problems of consciousness, the cognitive functions open to ordinary mechanistic explanation, from the hard one: why any of that function is accompanied by experience at all. "Even after we have explained the performance of all the cognitive and behavioural functions in the vicinity of experience," he wrote, "there may still remain a further question: why is the performance of these functions accompanied by experience?" [\[3\]](#ref-3) A functional duplicate of a person, identical in every behaviour, is conceivable with no experience inside it. If that is even coherent, experience is not a function, and no amount of added function guarantees it. A program built to maximise capability and scaled toward it never meets this question. It inherits it unnamed.

The traditions that took the question seriously did not converge on an answer, and that is the point. Maurice Merleau-Ponty argued in 1945 that mind is constituted through the body's sensorimotor coupling with the world, not housed in a mind that could in principle do without one. [\[4\]](#ref-4) He was reopening something the Cartesian line had spent three centuries closing. Classical Chinese philosophy had never made the cut: in the tradition of *xin*, the heart-mind, thinking, knowing, intention, and feeling are aspects of one process, and Roger Ames renders it "bodyheartminding," one word because the separation that would need three was never made. [\[5\]](#ref-5) This is convergence, not a case of the West catching up; a separate lineage reaching embodied integration on its own terms, and the comparison is contested even so. The Western bounded self, the thing a Cartesian splits from the body and an analytic philosopher tries to locate, is one contingent answer among several. The Upanishads held the self, *Atman*, to be unbounded, identical with the ground of all being. Buddhist thought refused even that, *anatta*, no stable self behind experience at all. These are not the same view in different dress. They are rigorous, opposed answers, argued for centuries, by people who had looked hard and landed in different places. The engineering tradition started from one of these answers, the post-Cartesian one, and built forward as though the contest were settled. It was not settled. The channels that carry the body, mortality, and social stakes were never sampled, the gap reached the training data unnamed, and a benchmark is not an answer to a millennium-old question. It is the decision to measure something else.

None of this would matter if the labs named the gap and built toward it with calibrated uncertainty. They have a different style.

---

## IV. The Confident Unknown

The labs know the gap is there. They have names for it, and the names do not close it.

Turing's substitution set the template, and benchmarks have run it ever since: a measurable output standing in for an undefined target. MMLU arrived as the flagship test of broad knowledge, the thing models were supposed to be acquiring. GPT-3 scored around 35%; frontier models now sit between 88% and 90%, close enough that the differences fall inside measurement noise. The climb is real. What the saturation shows is not that the target was reached but that the proxy ran out before anyone agreed what it was a proxy for, and the climbing continued. A 2025 interdisciplinary review put it plainly: benchmarks are "normative instruments that perpetuate particular epistemological perspectives about how the world is ordered." [\[6\]](#ref-6) A 2024 study found "cultural AI benchmarks often rely on implicit assumptions about measured constructs, leading to vague formulations with poor validity and unclear interrelations." [\[7\]](#ref-7) The tape measures were never neutral. They were built by people with assumptions about what a mind does, and the assumptions rode along as if they were the measurement.

John Searle named the underlying error in 1980. A person in a room follows rules to manipulate Chinese symbols and produces fluent Chinese without understanding a word: syntax is not semantics, and correct output does not entail comprehension. Benchmark failures are not all the Chinese Room; distribution shift, contamination, and Goodhart pressure each do their own damage. But the category error is the same one, behaviour accepted in place of the thing behaviour was meant to indicate. The evidence keeps arriving in the field's own terms. One preprint from November 2025 records a system scoring 60% on a single run and 25% across eight consecutive runs of the same task. [\[8\]](#ref-8) Same system, same task; the variance alone eats the headline number.

The training regime drives the confidence from inside. Zhou et al. found that "reward models used in PPO exhibit inherent biases towards high-confidence scores regardless of the actual quality of responses." [\[9\]](#ref-9) The optimisation does not reward being right about one's own uncertainty; it rewards sounding sure, because the people scoring outputs prefer answers that sound sure. The model that ships is the one that performs confidence best, and calibration is what the reward signal trims away.

David Hume reached the same wall in 1739, working only by introspection. He turned his attention on the thing doing the attending and found no one home. "I never can catch myself at any time without a perception, and can never observe any thing but the perception." [\[10\]](#ref-10) No stable knower behind the knowing, only a run of impressions the imagination stitches into a sense of unity. The mechanistic version is exact two centuries on: asked how confident it is, a model returns a number trained to sound calibrated, not produced by reading its own state, because there is no self-model under the report to read. Hume's bundle, restated as a training artifact.

The schedule rides on top of all of it. In January 2025 Sam Altman wrote, "We are now confident we know how to build AGI as we have traditionally understood it." [\[11\]](#ref-11) The work is in the last clause. He is not defining AGI; he is claiming to have met a definition assumed already to exist, and the post does not say whose, or how it would be checked. In April 2025 Demis Hassabis told CBS, "In the next five to ten years, I think," speaking of a system that "really understands everything around you," which he framed as a capability threshold rather than strict AGI. [\[12\]](#ref-12) A month later, to Axios, he placed AGI "just after 2030" and allowed that it needed "a couple more big breakthroughs"; Sergey Brin, same conversation, said just before. [\[13\]](#ref-13) The breakthroughs are unnamed. The dates are specific. The target is the one Turing declined to define.

The confusion is not an accident, and it does not require anyone to be lying. A specific date and a definition that sounds firm move capital; a calibrated unknown does not. The incentive runs one way at every level, the benchmark, the reward signal, the funding round, each rewarding a confident number over an honest gap, and the gap stays unnamed because naming it is expensive. This is not a recent lapse in rigour. It is Turing's 1950 substitution, still load-bearing, with a balance sheet attached.

I am not arguing the risk is zero. I am arguing the schedule is fiction.

---

## V. Clarification, Not Panic

The schedule is fiction. That the destination does not exist is a different claim, and not one I am making.

The risk is genuine. A decade is room enough for a surprise that resets the argument: a better training method, an architecture nobody has tried, a convergence no one saw. Any of them could close the question inside a generation, and I might be wrong. Ilya Sutskever stood in front of the audience that built the scaling era, in December 2024, and told them the data it ran on is nearly spent. That ceiling might give before it matters.

What is missing is support for the confidence, not for the possibility. The mechanism that carried the last decade of gains is, by the account of the people who built it, reaching its limit. The pivot to test-time compute and synthetic data may close the distance, or may not. A March 2025 AAAI survey of 475 researchers found 76% judged it unlikely or very unlikely that scaling current methods alone would reach AGI. [\[14\]](#ref-14) The case for near-term arrival is weaker than the marketing, and the people who know the machinery best are the ones saying so.

So the labs are billing for an answer to a question they have not defined, on a schedule drawn from measures they admit are saturated. The gap between the target and the proxy is not an honest unknown they are working to close. A confident date raises a round; a calibrated uncertainty does not.

The ask is small and it is not a demand to slow down. Say what you mean by the thing you are building, and hold the definition still long enough for someone outside the room to check it. The oldest question in philosophy got set aside in 1950 because it could not be measured, a measurable stand-in went up in its place, and the stand-in has been running for seventy-five years. A two-trillion-dollar industry now runs on it, and calls it progress.

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
