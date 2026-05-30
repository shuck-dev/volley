# The First Pass at a New Idea

A note on why an AI's first generation on a genuinely novel idea is weak, and what actually closes the gap. Bears on how to run prose and design work with agents.

## The observation

The first pass at a *new idea* tends to be poor, and this is structural, not a fluke of one model or prompt. It is about novel ideas, not first drafts: a first draft of a familiar pattern can be close, while a first pass at an unfamiliar framing is scratch reasoning regardless of polish.

## Generated tokens are computation

Intermediate tokens are not just output; they are serial computation a single forward pass cannot perform. Merrill & Sabharwal prove it formally ("The Expressive Power of Transformers with Chain of Thought," arXiv:2310.07923, 2023): without intermediate tokens a constant-depth transformer is limited to log-space; with a linear number of chain-of-thought steps it reaches context-sensitive languages; with polynomial steps, the full class of polynomial-time-solvable problems. Feng et al. ("Chain of Thought Empowers Transformers to Solve Inherently Serial Problems," arXiv:2402.12875, 2024) show CoT specifically unlocks problems requiring serial computation that a single pass cannot do at all. The original prompting result is Wei et al. (arXiv:2201.11903, 2022).

## More generation helps most on hard, novel problems

Test-time compute (the o1 line, survey arXiv:2501.02497) shows extending generation at inference measurably improves performance on hard problems: on AIME 2024, GPT-4o scores 12%, o1 single-sample 74%, best-of-1000 with learned reranking 93%. The gains concentrate on hard or out-of-distribution problems; familiar, easy tasks gain little.

## First-pass quality is lower on novel input, but degrades gracefully

Zhang et al. ("Generalization v.s. Memorization," ICLR 2025, arXiv:2407.14985) find factual recall is memorisation-driven while reasoning relies on generalisation, with a "generalization valley" where mid-complexity out-of-distribution tasks show the largest gap. The model degrades gracefully on novel input; it does not emit random output. "Nonsense" overstates it. The accurate description is a generalisation gap, not sludge.

## The critical qualification: revision needs external signal

Uninstructed self-revision does not reliably improve reasoning. Huang et al. ("Large Language Models Cannot Self-Correct Reasoning Yet," ICLR 2024, arXiv:2310.01798) show that *intrinsic* self-correction, with no external signal, often fails and sometimes degrades performance. Self-Refine (arXiv:2303.17651) and Reflexion (arXiv:2303.11366) work because their loops carry external grounding: a task-execution result, a verifier, a reward-shaped scaffold. So a new idea reasons through by generating against it *only when* the revision has external signal: human direction, a verifier, ground truth, or structured chain-of-thought. "Ask it to revise" in a vacuum is not a reliable path.

## What this means in practice

- Treat the first pass on a new idea as real-but-incomplete computation, not the answer. Expect to generate further.
- Make revision carry external signal: a concrete brief per pass, a verifier or audit, human direction, ground truth. Do not expect "make it better" with no signal to improve reasoning.
- Reserve the revision budget for genuinely novel work; familiar patterns do not need it.
