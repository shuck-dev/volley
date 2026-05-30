# Research Findings: Facet 4 -- Can mind exist without a body and a world?

Recovered from transcript agent-a97baf4939046aa3b.jsonl (2026-05-30). Agent had no Write tool; findings returned via StructuredOutput and final assistant text.

---

## Fusion verdict: REAL, with two required clarifications

The "absent from training data" argument is genuinely connected to the embodiment question -- but only if the essay keeps it as a **category claim, not a quantity one**. The argument is: text tokens about warmth, hunger, pain, and mortal urgency are not the same KIND of signal as the sensorimotor experience those words point at. You cannot read your way to proprioception. If the essay slips into "just missing enough diverse data," the fusion collapses and the overclaim risk fires. With that framing held, the pairing is real.

Second clarification: multimodal models with image and audio tokens blur the line. The argument applies most cleanly to text-only systems. The essay should note that adding image tokens is not the same as having a body.

---

## Sources

### Merleau-Ponty on embodiment

**Maurice Merleau-Ponty, *Phenomenology of Perception*, 1945 (French); 1962 English trans. Colin Smith, Routledge.**

Body schema formulation (from PhilArchive summary of Halak, "The Concept of 'Body Schema' in Merleau-Ponty's Account of Embodied Subjectivity"):
> "a practical diagram of our relationships to the world, an action-based norm with reference to which things make sense."

Core thesis: the body is not an object that mind inhabits but the very medium of being-in-the-world. Mind is constituted through sensorimotor coupling with an environment, not separable from it. The notion of the embodied mind "is meant to replace the ordinary notions of mind and body."

Key themes: "embodiment" and environmental "embeddedness."

Source URLs searched:
- https://philarchive.org/archive/HEIMAP-3
- https://philarchive.org/archive/POLMAE-3
- https://www.ncbi.nlm.nih.gov/pmc/articles/PMC4110438/
- https://philarchive.org/rec/HALTCO-38

### The Western detour and 4E rediscovery

**Descartes, *Meditations on First Philosophy*, 1641.**
Formal source of res cogitans / res extensa: mind and body as distinct substances that can exist independently. If mind and body are distinct entities, the interaction problem follows immediately. This is the split the 4E turn corrects.

**Varela, Thompson, Rosch, *The Embodied Mind*, MIT Press, 1991.**
> "cognition is brought forth by a living body coupled to its environment"
> "grounded not in the brain but in the sensorimotor systems of the body"

The 4E term (embodied, embedded, extended, enactive) originated here. The authors explicitly draw on Merleau-Ponty AND Buddhist phenomenology together, showing the rediscovery was already multi-traditional at its origin.

Note: The detour is specific, not universal. Aristotle's hylomorphism was not Cartesian dualism; Aquinas preserved form-matter unity. The detour should be attributed to the Cartesian lineage and its uptake in early cognitive science (computationalism, GOFAI -- Newell and Simon 1975; Fodor, *The Modularity of Mind*, 1983), not to "Western philosophy as a whole."

Source URLs searched:
- https://www.academia.edu/54508965/F_Varela_E_Thompson_E_Rosch_The_Embodied_Mind
- https://en.wikipedia.org/wiki/Embodied_cognition
- https://www.davidpublisher.com/Public/uploads/Contribute/6454c16f7a577.pdf

### Classical Chinese xin (heart-mind) -- sinology check

**Stanford Encyclopedia of Philosophy, "Mind (Heart-Mind) in Chinese Philosophy."**
URL fetched: https://plato.stanford.edu/entries/chinese-mind/ (retrieved 2026-05-30)
This is the authoritative English-language sinology reference for this claim.

Verified claims from the SEP entry:

xin integrates:
> "thinking, understanding, knowing, intention, emotions, and desire"
into a unified system that guides behaviour and ethical development.

The moral sprouts (duan) in Mencian thought:
> "include emotions" and possess "cognitive content embedded within them." The heart-mind isn't "a slave to emotion, but neither does it act independently of emotion when it acts morally."

**Roger Ames** formulation, cited in SEP entry:
> "bodyheartminding" -- qi constitutes "not merely the somatic, bodily dynamics, but also the motivating force of thoughts, emotions, and intentions."

Mind, body, and vital energy (qi) are aspects of one process, not separate substances.

**Francois Jullien**, cited in SEP entry:
> "organic being and animation both emerge from qi," avoiding ontological separation.

Daoist stream (Daodejing, Zhuangzi): xin as part of the process of de (practical competence) in concrete embodied worldly action. Artisans, gymnasts, philosophers all enact mind through bodily engagement with the world.

**Chronology**: This is the baseline position of classical Chinese philosophy from at least the Warring States period (c. 475-221 BCE), predating Descartes by nearly two thousand years. It is not a modern synthesis.

Additional search sources:
- https://grokipedia.com/page/xin_heart_mind
- https://en.wikipedia.org/wiki/Xin_(heart-mind)
- https://www.mdpi.com/2077-1444/16/9/1097
- https://link.springer.com/article/10.1007/s11712-020-09760-x

### Present: absent modalities in LLMs

**Kadambi, A., Aziz-Zadeh, L., Damasio, A., Iacoboni, M., & Narayanan, S. (2025). "Embodiment in multimodal large language models." arXiv 2510.13845.**
URL fetched: https://arxiv.org/html/2510.13845v1

Verbatim claims recovered from WebFetch:
> "MLLMs still lack any bodily experience. They interpret 'heat' without ever feeling warmth, parse 'hunger' without ever knowing need."

> "These layers of inference further influence higher cognition and the experience of prosocial constructs such as empathy and social reasoning."

> "Language itself is to some extent grounded on such embodied experiences" in humans, whereas current systems process language purely statistically without sensorimotor connection.

> "MLLMs also lack mechanisms for encoding and retrieving memories in structured, state-dependent ways."

Identified missing channels: proprioception (body position and movement), interoception (internal states), embodied social reasoning (empathy grounded in felt mirroring).

CAUTION: This is a 2025 preprint, not settled cognitive science. Use as illustration of the argument structure, not as proof of consensus.

**"Will multimodal large language models ever achieve deep understanding of the world?" PMC/Frontiers 2025.**
URL: https://pmc.ncbi.nlm.nih.gov/articles/PMC12679578/

From WebSearch summary:
> "Embodiment, symbol grounding, causality and memory are foundational problems required for LLMs to attain human-level general intelligence."

> "large language models are merely statistics-driven distributional models without a deeper understanding due to the symbol grounding problem."

**Harnad, S. (1990). "The Symbol Grounding Problem." *Physica D*, 42(1-3), 335-346.**
Not fetched directly; cited by the agent as bridging literature between Merleau-Ponty and the AI embodiment debate. The referents of symbols cannot be grounded in other symbols alone; grounding requires sensorimotor coupling. This is the computational-era statement of the embodiment argument.

---

## Load-bearing claims

1. The West had a roughly 350-year detour (Descartes 1641 to Varela-Thompson-Rosch 1991) from mind-body dualism back toward what the Chinese tradition never separated.

2. Classical Chinese xin integrates cognition, affect, and bodily vital energy (qi) into a single process from at least the Warring States period (c. 475-221 BCE). This is not a modern synthesis; it is the baseline classical Chinese position.

3. Merleau-Ponty's embodiment thesis: mind cannot exist without the sensorimotor coupling that constitutes it. It is a property of a body-in-the-world, not of an isolated mind.

4. The signal absent from text-only training is not thin in quantity but different in kind: proprioceptive, interoceptive, mortal, and social-stakes channels that cannot be reconstructed from statistical co-occurrence of tokens that describe them.

5. This makes the missing-channels argument a **category claim** (a different kind of signal was never present) rather than a competence claim (more training would close the gap). The essay's signal metaphor lives or dies on this distinction.

6. Varela et al. (1991) explicitly used Merleau-Ponty AND Buddhist phenomenology together. The 4E rediscovery was already multi-traditional at its origin, reinforcing that the West was the outlier, not the originator.

---

## Overclaim risks

1. **Saying xin "proves" the West wrong.** xin is a parallel tradition that reached a similar position independently and for its own reasons. Name the parallel, not a correction.

2. **"The West uniformly lost embodied cognition."** Aristotle's hylomorphism was not Cartesian dualism. Attribute the detour specifically to the Cartesian lineage and its uptake in computationalism, not to Western philosophy as a whole.

3. **Claiming absent modalities alone prove models cannot be minded.** That would require settling the hard problem of consciousness. The argument is evidential (category gap), not conclusive.

4. **Treating the Kadambi 2025 arXiv paper as settled cognitive science.** It is a preprint. Use as illustration only.

5. **Treating multimodal models as obviously not closing the gap.** The Kadambi paper argues even MLLMs lack true embodied grounding, but this is contested. Acknowledge the debate rather than treating text-only as the only target.

---

## Xin sourcing status

**SOURCED against sinology.** The SEP entry "Mind (Heart-Mind) in Chinese Philosophy" was fetched directly and confirms the unified cognitive-affective-somatic character of xin, the Roger Ames "bodyheartminding" formulation, and the Warring States chronology. The claim is not pop-orientalism as long as the essay names what xin integrates and does not reduce it to "the East is holistic." The Daoist / Confucian difference is present in the SEP material: Confucian xin leads the person through integration of all functions including virtue embodied in relation; Daoist stream emphasises de (practical competence) in concrete worldly action.

What is NOT sourced in this transcript: any direct quotation from primary Chinese texts (Analects, Mencius, Zhuangzi, Daodejing) in the original or in a named scholarly translation. The transcript relies on the SEP secondary account. If the essay needs primary-text quotation, that requires a separate fetch.

---

## Named claims in StructuredOutput

The researcher returned an empty `named_claims` array. No named public quotes (speaker / date / venue / exact words) were collected for this facet. Facet 5 carries the named-claims load for the essay.
