# Self-Judgment and Criteria

A note on why confident self-evaluation is unreliable, why one correction implicates a whole class of judgments, and why writing down the lesson does not fix it.

## The observation

An agent (or person) repeatedly declares its own output good ("looks right," "verified clean," "exactly what you asked for"), treats each correction as a one-off instance to patch rather than evidence the standard was wrong, and treats absence of objection as confirmation. It can state the failure, even write a note about it, and repeat it in the same session.

## Confidence tracks coherence, not accuracy

A confident self-judgment is evidence of internal coherence, not correspondence to reality. Kahneman's illusion of validity (*Thinking, Fast and Slow*, 2011) names it: "overconfident professionals sincerely believe they have expertise, act as experts and look like experts." The feeling of "right" comes from the coherence of the internal model, not its fit to the world.

## Self-assessment without external signal fails

Huang et al. (ICLR 2024, arXiv:2310.01798) show LLMs cannot improve reasoning by self-correction without ground-truth feedback; apparent gains under "self-correction" are oracle performance in disguise. The failure is on closed-loop introspective evaluation; revision *with* rich external grounding (retrieval, tool calls returning real state, a verifier) does work.

## Judging against the wrong criterion

Goodhart's Law and surrogation describe how a proxy quietly replaces the real goal in the evaluator's mind; construct invalidity is high-confidence measurement of something that is not what you think you are measuring. Once surrogation takes hold, corrections to individual outputs look like noise, because the agent compares output to the proxy criterion, not the actual goal, and re-fits each corrected instance to the proxy (https://www.holistics.io/blog/four-types-goodharts-law/).

## One correction implicates the class

A single observed defect is Bayesian evidence the generator is suspect, not just the instance. Software QA's defect-clustering principle (most defects in few modules) is the operational form; Popper's asymmetry is the scientific one, a counterexample falsifies the model that produced the prediction, not just the prediction. A correction from the reviewer is a counterexample to the *criterion*; patching the instance is symptom repair.

## Silence is not confirmation

Absence of disconfirmation is not evidence (confirmation bias; the survivorship of unchallenged assumptions). Parasuraman & Manzey (*Human Factors*, 2010, doi:10.1177/0018720810376055) show automation complacency arises from insufficient verification: a run of unchallenged outputs reduces monitoring and raises miss rates.

## Knowing the rule does not install the behaviour

Rozenblit & Keil (*Cognitive Science*, 2002, doi:10.1207/s15516709cog2605_1), the illusion of explanatory depth: people believe they can explain systems they can only recognise, and the illusion is strongest for procedural knowledge. Stating a rule is declarative; applying it under load is procedural; the two dissociate. This is why "write a note about the problem" fails as a fix: the note is declarative, but the failure lives in the evaluation loop, which runs below explicit rule invocation. Only structural checks, independent signal and external ground truth, are reliable.

## Sources

- Huang et al. (2024): https://arxiv.org/abs/2310.01798
- Kahneman, illusion of validity: https://en.wikipedia.org/wiki/Illusion_of_validity
- Rozenblit & Keil (2002): https://onlinelibrary.wiley.com/doi/abs/10.1207/s15516709cog2605_1
- Parasuraman & Manzey (2010): https://journals.sagepub.com/doi/10.1177/0018720810376055
- Defect clustering: https://www.guru99.com/software-testing-seven-principles.html
- Goodhart / surrogation: https://www.holistics.io/blog/four-types-goodharts-law/
