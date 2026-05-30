# Check: the "37% lab-to-production gap" statistic

Verdict: **CUT.** The figure cannot be verified to a credible primary source.

## The citation chain (traced to ground)

1. The sole traceable paper containing the figure is "Beyond Accuracy: A Multi-Dimensional Framework for Evaluating Enterprise Agentic AI Systems" (Sushant Mehta, arXiv:2511.14136). Solo-authored preprint, not peer-reviewed.
2. It cites the 37% in passing as "(Liu et al. 2024)" with no further detail.
3. "Liu et al. 2024" resolves to arXiv:2412.05449 ("Towards Effective GenAI Multi-Agent Collaboration", Amazon/AWS). That paper contains no 37% lab-to-production figure; it measures multi-agent coordination success rates, not benchmark-vs-deployment divergence.
4. The figure circulating in blog posts and search summaries (kili-technology.com, Medium, aggregators) traces back to the same preprint or to each other. None link to an original measurement.

The statistic has no verifiable origin. Using it invites a citation challenge that cannot be answered.

## Recommendation

CUT the 37% figure. Replace with structural language ("benchmark scores routinely diverge from real-world capability") and cite arXiv:2511.14136 only for the adjacent finding it does document: performance dropping from 60% on a single-run eval to 25% across eight consecutive runs. That figure is in the paper and is directly relevant to the behavioural-proxy-vs-target argument.

**OPEN: verify the publication date of arXiv:2511.14136 before citing.** The recovery agent reported "November 2024" but the 2511 arXiv prefix encodes November 2025. The essay must cite the correct date.

## Sources

- Beyond Accuracy (arXiv:2511.14136): https://arxiv.org/abs/2511.14136
- Towards Effective GenAI Multi-Agent Collaboration (arXiv:2412.05449): https://arxiv.org/abs/2412.05449
- Kili Technology, AI Benchmarks 2026: https://kili-technology.com/blog/ai-benchmarks-guide-the-top-evaluations-in-2026-and-why-theyre-not-enough
