# Facet 5 Research: Who gets to say what counts, and why does it pay?

Recovered from transcript agent-a3494ccbf98449810.jsonl. The original researcher had no Write tool; findings were returned via StructuredOutput only and never reached disk.

---

## Fusion Verdict

**REAL, but structurally the weakest of the five.**

The ancient claim: the unified western self is one contingent answer to "what is a mind," not a neutral description. The present claim: AGI benchmarks, AGI definitions, and RLHF reward signals all operationalise that same contingent self-model as though it were a neutral measurement frame.

The link holds because "what gets measured as AGI" inherits assumptions about what a mind is, exactly the contingency facets 1 and 4 expose from the inside. The RLHF-rewards-confidence finding is empirically documented (arXiv 2410.09724) and is not just rhetorical.

The overclaim risk: conflating two separable claims. (a) Benchmarks embed epistemological priors -- a sociology-of-science claim, well-supported. (b) Those priors reduce specifically to the western unified self -- a stronger philosophical claim that needs more bridging. The essay can assert (a) with receipts; it should hedge (b) as the contested interpretive frame, not a demonstrated fact.

---

## Named AGI Timeline Claims (verbatim, attributed, sourced)

### Claim 1 -- Sam Altman

**Speaker:** Sam Altman, CEO of OpenAI  
**Venue:** Personal blog, "Reflections," blog.samaltman.com  
**Date:** ~January 8 2025 (internal context: "The second birthday of ChatGPT was only a little over a month ago")  
**URL:** https://blog.samaltman.com/reflections

**Verbatim quote:**
> "We are now confident we know how to build AGI as we have traditionally understood it."

**Secondary quote from same post:**
> "We believe that, in 2025, we may see the first AI agents join the workforce and materially change the output of companies."

**Note:** "as we have traditionally understood it" is doing enormous definitional work and must be flagged in the essay if this quote is used.

---

### Claim 2 -- Demis Hassabis (Axios, May 2025)

**Speaker:** Demis Hassabis, CEO of Google DeepMind  
**Venue:** Axios interview, reporter Ina Fried  
**Date:** Published May 21 2025  
**URL:** https://www.axios.com/2025/05/21/google-sergey-brin-demis-hassabis-agi-2030

**Summary of claim:** Predicted AGI "just after 2030," said "a couple more big breakthroughs" still needed.

**Companion claim (same article):** Sergey Brin (Google co-founder) predicted AGI "just before 2030."

**Note:** No direct verbatim quote was retrieved from this article (HTTP access succeeded but content was paraphrased by the fetch tool). The "just after 2030" framing is the Axios reporter's characterisation, confirmed across multiple search results. Use as reported claim with URL; do not present as direct quote.

---

### Claim 3 -- Demis Hassabis (CBS News / 60 Minutes, August 2025)

**Speaker:** Demis Hassabis  
**Venue:** CBS News / 60 Minutes  
**Date:** August 2025 (per CBS News article)  
**URL:** https://www.cbsnews.com/news/artificial-intelligence-google-deepmind-ceo-demis-hassabis-60-minutes-transcript/

**Verbatim quote:**
> "In the next five to ten years, I think"

**Context:** Referring to "a system that really understands everything around you in very nuanced and deep ways and are kind of embedded in your everyday life." This quote may refer to a capability threshold short of strict AGI; the essay must not conflate it with the 2030 AGI claim without noting the qualifier.

---

## RLHF Finding

**Source:** Zhou et al., "Taming Overconfidence in LLMs: Reward Calibration in RLHF," arXiv:2410.09724, October 2024  
**URL:** https://arxiv.org/abs/2410.09724  
**OpenReview:** https://openreview.net/forum?id=l0tg0jzsdL

**Verbatim claims from paper (via fetch):**
> "RLHF tends to lead models to express verbalized overconfidence in their own responses."

> "reward models used in PPO training exhibit inherent biases towards high-confidence scores regardless of the actual quality of responses."

**What the paper proposes:** Two remedies (PPO-M, PPO-C) to calibrate reward models against expressed confidence. The fact that remedies are needed confirms the bias exists in standard RLHF pipelines.

**Overclaim risk:** This is a technical paper proposing a fix, not a settled consensus finding. Cite as documented concern, not proven law.

---

## Defensible RLHF-as-Cultural-Prior Sentence

The researcher's own synthesis (from StructuredOutput, line 35 reasoning block):

> RLHF trains models to sound confident because annotators reward confident-sounding output, so the models that get deployed are the ones that perform the epistemic style of the institutions that built them; calibrated uncertainty does not survive the reward signal.

This is the "folded remnant of the cut exceptionalism thread" per the dandori. It is supportable. The further inference -- that this is a cultural prior rather than a neutral engineering outcome -- requires the essay to make the bridge explicit.

---

## Benchmarks-Encode-Priors Sources

### Source A

**Paper:** "Can We Trust AI Benchmarks? An Interdisciplinary Review of Current Issues in AI Evaluation"  
**arXiv:** 2502.06559  
**Date:** 2025  
**URL:** https://arxiv.org/html/2502.06559v2

**Verbatim claim (from paper):**
> "normative instruments that perpetuate particular epistemological perspectives about how the world is ordered"

**Verbatim claim (characterising the embedded assumptions):**
> "valuing efficiency at the expense of care; universality at the expense of contextuality; impartiality at the expense of positionality; and model work at the expense of data work"

**Additional characterisation from paper:**
> "Benchmark practices are fundamentally shaped by cultural, commercial and competitive dynamics that often prioritise state-of-the-art performance at the expense of broader societal concerns."

---

### Source B

**Paper:** "Exposing Assumptions in AI Benchmarks through Cognitive Modelling"  
**arXiv:** 2409.16849  
**Date:** 2024  
**URL:** https://arxiv.org/html/2409.16849

**Verbatim claim:**
> "Cultural AI benchmarks often rely on implicit assumptions about measured constructs, leading to vague formulations with poor validity and unclear interrelations."

---

## Load-Bearing Claims (for the essay)

1. RLHF reward models exhibit systematic bias toward high-confidence outputs regardless of actual response quality; documented in peer-reviewed work (arXiv 2410.09724), not just asserted.
2. Benchmarks are normative instruments encoding their makers' epistemological priors, not neutral measurement frames; supported by at least two 2024-2025 interdisciplinary reviews (arXiv 2502.06559, 2409.16849).
3. Sam Altman declared in January 2025 that OpenAI is "confident we know how to build AGI as we have traditionally understood it"; a live, sourced claim on a schedule.
4. Demis Hassabis predicted AGI "just after 2030" in May 2025 (Axios); the timeline is being publicly committed and is moving.
5. The target of "AGI" is undefined in a stable, cross-institutional way; every lab's benchmark for it encodes assumptions about what a mind does, not what a mind is.

---

## Overclaim Risks

- Asserting that benchmarks specifically encode the "western unified self" is a stronger philosophical claim than the sociology-of-science papers support directly. They show cultural and commercial bias, not a specific lineage to a Cartesian self-model. The essay must bridge this gap explicitly or soften the claim.
- The AGI timeline quotes from Hassabis move around (five to ten years in CBS, just after 2030 in Axios). Using them as "a schedule" is fair only if the essay acknowledges the definitional vagueness Altman himself embeds.
- The RLHF-rewards-confidence paper (2410.09724) is a technical paper proposing a fix, not settled consensus. Cite as documented concern, not proven law.
- "The confusion pays, so it persists" as a conscious institutional strategy is an inference. The papers support that the confusion exists and that incentive structures do not correct for it, which is the stronger and safer version.
- The Hassabis CBS quote ("five to ten years") may refer to a different capability threshold than strict AGI. Conflating all these quotes as "AGI by year X" risks misrepresenting each speaker's careful hedging.

---

## Sources Index

| # | Citation | URL |
|---|----------|-----|
| 1 | Sam Altman, "Reflections," blog.samaltman.com, ~January 8 2025 | https://blog.samaltman.com/reflections |
| 2 | Demis Hassabis, Axios (Ina Fried), May 21 2025 | https://www.axios.com/2025/05/21/google-sergey-brin-demis-hassabis-agi-2030 |
| 3 | Demis Hassabis, CBS News / 60 Minutes, August 2025 | https://www.cbsnews.com/news/artificial-intelligence-google-deepmind-ceo-demis-hassabis-60-minutes-transcript/ |
| 4 | Zhou et al., "Taming Overconfidence in LLMs: Reward Calibration in RLHF," arXiv:2410.09724, Oct 2024 | https://arxiv.org/abs/2410.09724 |
| 5 | "Can We Trust AI Benchmarks?", arXiv:2502.06559, 2025 | https://arxiv.org/html/2502.06559v2 |
| 6 | "Exposing Assumptions in AI Benchmarks through Cognitive Modelling," arXiv:2409.16849, 2024 | https://arxiv.org/html/2409.16849 |
