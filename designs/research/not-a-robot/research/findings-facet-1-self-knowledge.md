# Facet 1: Can a thing know its own mind?

**Fusion verdict:** REAL but asymmetric. The Humean strand carries tightly. The Upanishadic and Buddhist strands carry genuine resonance but serve different ends. Do not flatten the three into one "ancient view."

---

## Ancient sources

### Hume, *A Treatise of Human Nature* (1739), Book I, Part IV, Section VI

Verbatim: "I never can catch *myself* at any time without a perception, and can never observe any thing but the perception."

Bundle theory: introspection yields no unified observer, only a succession of impressions. The self is "a bundle or collection of different perceptions, which succeed each other with an inconceivable rapidity and exist in a perpetual flux and movement." Identity is an illusion forged by the imagination through relations of resemblance, contiguity, and causation. No stable knower behind the knowing.

Sources: [SparkNotes, Bundle Theory summary](https://www.sparknotes.com/philosophy/hume/idea-bundle-theory/); [Colin McLear, Hume on Personal Identity](https://notebook.colinmclear.net/teaching-notes/humeidentity/); [Routledge Encyclopedia of Philosophy, Bundle theory of mind](https://www.rep.routledge.com/articles/thematic/mind-bundle-theory-of/v-1).

### Brihadaranyaka Upanishad (c. 700 BCE), Yajnavalkya's teaching

Verbatim (2.4.5): "You cannot see the seer of seeing; you cannot hear the hearer of hearing; you cannot think of the thinker of thinking; you cannot know the knower of knowing. This is your self that is within all; everything else but this is perishable."

Verbatim paradox (same text): "He who thinks that he knows Brahman does not know it. He who thinks that he does not know Brahman, he knows it."

The Atman is the irreducible witnessing awareness that cannot be made an object of experience. The Upanishadic project is soteriological: removing misidentification (body, senses, mind, name, social role) until only the witness remains, and that recognition is moksha. This is not an epistemological calibration claim; it is a claim about ontological primacy.

Sources: [Hinduwebsite, Brihadaranyaka summary](https://www.hinduwebsite.com/upanishads/brihad/); [yogananda.com.au, Brihadaranyaka text](https://yogananda.com.au/upa/Brihadaranyaka02_Upanishad.html), retrieved 2026-05-30.

### Buddhist anatta (not-self), deliberate refutation of Atman

Per K.N. Jayatilleke (cited via Encyclopedia MDPI, entry/34603): the Buddhist inquiry "is satisfied with the empirical investigation which shows that no such Atman exists because there is no evidence." The Upanishadic inquiry recognises many things as not-self but still assumes a real Atman can be found; Buddhism treats literally everything, including Nirvana, as non-self.

Anatta is less a metaphysical declaration than a practical direction: stop grasping at any aspect of experience as "me" or "mine," because that grasping is the root of suffering. The question "who is the knower?" has no stable answer; the teaching is to stop asking it as though it had one.

Sources: [Encyclopedia MDPI, Anatta entry](https://encyclopedia.pub/entry/34603); [1000-Word Philosophy, The Buddhist Theory of No-Self](https://1000wordphilosophy.com/2023/02/25/no-self/).

---

## Present sources

### "Taming Overconfidence in LLMs: Reward Calibration in RLHF" (2024)

arXiv: [2410.09724](https://arxiv.org/abs/2410.09724)

Verbatim: "RLHF tends to lead models to express verbalized overconfidence in their own responses."

Mechanism verbatim: "Reward models used in PPO exhibit inherent biases towards high-confidence scores regardless of the actual quality of responses."

The training signal rewards confident-sounding output. Expressed certainty decouples from actual accuracy. This is a mechanistic finding, not only a behavioural observation.

### "Rewarding Doubt: A Reinforcement Learning Approach to Calibrated Confidence Expression of Large Language Models" (2025)

arXiv: [2503.02623](https://arxiv.org/pdf/2503.02623)

RLHF-tuned models primarily emit verbalized confidence scores between 80% and 100%. Expected Calibration Error (ECE) values reach 0.30+ on knowledge-intensive tasks, meaning expressed confidence overshoots actual accuracy by up to 30 percentage points. Miscalibration is concentrated "at the knowledge boundary," precisely where self-knowledge would matter most.

### "Can LLMs Express Their Uncertainty?" (OpenReview)

[openreview.net/pdf?id=gjeQKFxFpZ](https://openreview.net/pdf?id=gjeQKFxFpZ)

Frames the problem as the model's inability to accurately represent what it does and does not know. The gap between internal model confidence and verbalized confidence is the calibration gap.

---

## Load-bearing claims the essay can safely assert

1. Hume's bundle theory and the LLM calibration problem share a structural identity: in both cases, introspection (or its analogue) cannot reach a reliable, unified observer, and the self-report is not transparent to the underlying state.

2. RLHF mechanistically trains models toward confident expression independent of actual accuracy. Reward models exhibit "inherent biases towards high-confidence scores regardless of the actual quality of responses" (arXiv 2410.09724). This is a mechanistic finding.

3. The Brihadaranyaka paradox ("he who thinks he knows Brahman does not know it") is a precise ancient formulation of the epistemic trap a miscalibrated model falls into: the more confidently it asserts, the more it demonstrates it does not know what it is asserting.

4. The expressed-vs-actual confidence gap is largest at the knowledge boundary, where self-knowledge would matter most.

5. The three ancient traditions (Hume, Upanishadic Vedanta, Buddhist anatta) are not one view. Hume leaves empiricism intact. The Upanishads posit an ultimate witness-self that transcends objectification. Anatta dissolves the knower-question as a conceptual trap for liberation. The essay must not flatten them.

---

## Overclaim risks

- **Merging the three ancient traditions.** They give incompatible accounts of what the missing knower means. Flattening them into one "ancient view" misrepresents at least one, probably all three.

- **Claiming calibration failure IS the self-knowledge problem in full.** It instantiates the ancient structure but does not include phenomenal consciousness or the question of what it is like to be uncertain. The ancient problem is wider.

- **Claiming RLHF overconfidence is deliberate design.** The papers treat it as a training artifact. The defensible claim: confident-sounding output is incentivised by the training regime. Implication that labs designed this knowingly is unsupported.

- **Using Upanishadic material as a Western epistemology prop.** The Brihadaranyaka "know the knower" teaching is soteriological, not a calibration claim. Using it without noting the soteriological frame imports exotica rather than the tradition's own meaning.

---

## Fusion verdict (full reasoning)

**Humean strand (tightest joint):** Hume's finding is that introspection does not yield a stable, unified knower. Applied to an LLM: when the model reports high confidence, no introspective access to its own parametric uncertainty is occurring; only a surface-level token pattern trained to sound certain. The structural identity is genuine. Same problem, 285 years apart.

**Upanishadic strand (real, oblique):** The Brihadaranyaka paradox maps onto the miscalibrated model's epistemic trap at the surface. But the Upanishadic claim is ontological (the witness-self cannot be objectified) while calibration is statistical (expressed confidence overshoots actual accuracy). These are neighbours, not identical. Use for flavour; do not claim parity of purpose.

**Buddhist anatta (resonant, differently motivated):** Anatta dissolves the knower-question as a conceptual trap for liberation. The model's lack of a self-model is an architectural fact, not a liberatory insight. The resonance is real; the motivation is distinct. Gloss carefully.

**Overall verdict:** KINSHIP is fully justified; BOLD IDENTITY holds only for the Humean strand. Lead with Hume for the tightest joint.
