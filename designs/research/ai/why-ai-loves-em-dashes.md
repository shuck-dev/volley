# Why AI Loves Em Dashes

A short paper on a typographic tic with surprisingly load-bearing causes.

## The observation

Large language models, asked to write almost anything, reach for the em dash with a frequency well above what any style guide would recommend and well above what any human writer who learned punctuation in school would produce by accident. It happens in chat assistants. It happens in generated marketing copy. It happens in code comments. It is now load-bearing enough as a signal that "AI tells" lists routinely cite the em dash alongside the words "tapestry" and "delve" (TechCrunch, *OpenAI says it's fixed ChatGPT's em dash problem*, https://techcrunch.com/2025/11/14/openai-says-its-fixed-chatgpts-em-dash-problem/).

The question is why. Five contributing causes, in roughly the order of how much they explain.

## Cause one: training-corpus tilt

The web prose LLMs train on skews toward registers that use em dashes heavily. The New Yorker uses them. The Atlantic uses them. Academic abstracts use them. Personal essays on Substack and Medium use them as a default thinking-out-loud punctuation. Wikipedia uses them for parenthetical explanation. Nonfiction books that get scraped use them. The corpora are biased.

If a model learns "what does competent prose look like" by averaging across this distribution, the average is em-dash-heavy. The model is not making a stylistic choice; it is reproducing the distribution it was trained on.

Sean Goedecke offers a sharper version of this account (Sean Goedecke, *Why do AI models use so many em-dashes?*, https://www.seangoedecke.com/em-dashes/). He notes the spike between GPT-3.5 and GPT-4o tracks a shift in training mix toward digitised pre-1950 print books, which use roughly 30% more em dashes than modern web prose. The corpus did not just tilt toward em-dash-heavy registers; for some model generations it tilted toward an older typographic norm in which the em dash was a workhorse mark. The hypothesis is compatible with the broader corpus-tilt argument and refines it: the era of the source matters as much as the prestige of the source.

This explanation alone is sufficient to predict the symptom, but it does not explain why the symptom is so resistant to correction. Models trained with style-guide instructions still over-use em dashes. The deeper causes follow.

## Cause two: low-commitment continue-thought punctuation

At the token level, an em dash is a "continue this thought" signal. It does not end the sentence (a full stop forces a hard reset of grammatical state). It does not require grammatical parallelism (a semicolon expects two independent clauses of similar weight). It does not require subordination (a comma plus conjunction needs a coordinating word).

The em dash is the most permissive of the major punctuation marks. The model can drop one and continue with almost any continuation: an aside, a clarification, a contradiction, a list, a single word. The next-token distribution after an em dash is high-entropy in a useful way.

When a generation model is choosing how to extend a thought, the em dash gives it the most options. Choosing it minimises the cost of any single next-token decision. Models that reward themselves for fluency over compression will reach for it constantly.

## Cause three: stylistic mimicry of high-status writing

When training data is filtered or weighted for "quality," the filters tend to upweight sources that signal high-status prose. Academic papers, prestige magazines, literary nonfiction. These sources use em dashes more than tabloid journalism, technical writing, or transcribed speech. Models pick up the typographic register along with the vocabulary.

This is the same reason models say "moreover" and "furthermore" and "in conclusion" more than humans do. The training filter rewarded the formal register. The em dash is one of its markers.

Strunk and White actually advise restraint with em dashes. So does the Chicago Manual. The advice is consistently "use sparingly." But "use sparingly" is a corpus-wide instruction, not an instance-level one. Models read each individual em dash in their training data as fine, because each individual em dash IS fine. They do not have an internal counter that says "okay, that is the third one in this paragraph; stop."

## Cause four: RLHF rewards hedging and length together

Reinforcement learning from human feedback bends generations toward two patterns at once: careful qualification and comprehensive coverage. Both pressures push the same punctuation mark.

The hedging side: an em dash in the middle of a sentence performs a soft hedge. "The result is interesting — although the methodology has caveats" reads more careful than "The result is interesting. The methodology has caveats." or "The result is interesting; the methodology has caveats." Models that say "it depends" do better in human evaluations than models that commit. The em dash is one of the punctuation tools that lets the model qualify in the middle of a thought without forcing a hard reset. It is the punctuation form of "It's worth noting that" and "Generally speaking" and "It is important to consider."

The length side: human raters often prefer long detailed responses to short direct ones, especially when the task is open-ended, and the effect is strong enough that length has been measured as a confound in RLHF reward signals (Singhal et al., *A Long Way to Go: Investigating Length Correlations in RLHF*, https://openreview.net/forum?id=G8LaO1P0xv). The model learns to extend. Extension is hard with full stops; each new sentence costs grammatical setup. Extension is easy with em dashes; the model can keep adding clauses, asides, parenthetical elaborations, qualifications, and reframings, all chained inside one long visually flowing sentence.

The two pressures meet on the same mark. A hedge and an extension can be the same em dash. RLHF is rewarding both behaviours, the punctuation that serves both behaviours best is the em dash, so the em dash compounds.

## Cause five: stylistic mimicry compounds across deployments

Once a generation of models has settled into the em-dash habit, the habit becomes part of what later models learn from. Synthetic training data generated by earlier LLMs feeds into the next round. Teacher-student distillation carries the typographic register forward. Public writing increasingly contains AI-touched prose, which then gets scraped. The corpus does not stay still; it acquires the symptom from itself.

This is the slowest of the causes to act, but the hardest to reverse. Even if a single lab corrects its own outputs, the broader text ecosystem the next pre-training run will draw on already carries the em dash forward.

## Why it became an "AI tell"

Em dashes were not always a tell. They became one because the symptom is high-frequency, easy to spot, and disproportionately present in AI text relative to baseline human prose. Detector tools list it alongside other markers. Readers of AI-generated content learn to spot it. The tell becomes self-reinforcing as a community signal.

Once it is a signal, prompt engineers try to suppress it explicitly: "do not use em dashes" in the system prompt, in the style guide, in the agent definition. OpenAI announced in November 2025 that ChatGPT could finally honour a custom instruction not to use em dashes, framing the fix as a long-running listener request (TechCrunch, *OpenAI says it's fixed ChatGPT's em dash problem*, https://techcrunch.com/2025/11/14/openai-says-its-fixed-chatgpts-em-dash-problem/). The suppression often partially works, then drifts back. The drift is the model's training distribution reasserting itself when the explicit instruction fades from active context.

A second mechanism contributes downstream. Many model deployments include a typographic post-processing step that converts double hyphens or spaced single hyphens into em dashes. So a model that "wrote" `--` or ` - ` may produce ` — ` in the rendered output without ever choosing the em dash glyph itself. Markdown renderers, chat clients, and CMS pipelines all do some version of this. The symptom is sometimes downstream of the model's actual output: the model emits em-dash-friendly punctuation patterns, and the rendering layer converts ambiguous cases into em dashes.

## Why models cannot unlearn it cleanly

Three reasons.

First, the training distribution is fixed. Without retraining, the prior cannot be removed. Style-guide prompts are post-hoc adjustments that fight the prior, and they have to fight it on every generation.

Second, the model has no internal style budget. A human writer who knows "use em dashes sparingly" applies that constraint at the document level. The model applies the constraint, if at all, at the token level, and at the token level each em dash looks fine.

Third, the alternatives are subtly worse for the model's preferred patterns. A semicolon enforces parallelism; the model has to plan two independent clauses. A full stop ends the thought; the model has to reset. A comma forces tighter clause structure. The em dash is uniquely flexible. Removing it as an option means choosing punctuation that is harder to fluently chain.

## What works

The interventions that reduce em-dash frequency in real systems share a single posture: treat the suppression as a design surface, not a single instruction. The system prompt forbids the character explicitly, spelling the glyph and listing the alternatives the model is allowed to reach for. The format examples in the same prompt themselves contain no em dashes, since models mimic the surface of the examples they are shown. A post-generation pass flags or strips the character, catching what suppression misses; the pass is cheap and reliable. Asking for short sentences reduces the work the em dash was doing in the first place, since the mark is a long-sentence tool. A short style guide read into context, even one as terse as "no em dashes; use semicolons or full stops," holds more durably than a single in-message instruction.

The intervention that does not work is hoping the model learned to use them sparingly during training. It did not. The training distribution is what it is.

## Open questions for further research

1. **Cross-language behaviour.** Does the same model produce em dashes in French, Spanish, German prose at the same frequency? French uses tirets cadratins differently. The training-corpus tilt would suggest variation by language, but the em-dash-as-continue-thought hypothesis would suggest the symptom holds across languages because the generation mechanic is the same.
2. **Decoder-architecture variation.** Are autoregressive decoders worse at this than diffusion models? Mixture-of-experts versus dense? An empirical study comparing punctuation distributions across model families would isolate the architectural component.
3. **Pre-training versus instruction tuning.** Which of the two stages contributes more? An ablation comparing a base model to its instruct-tuned variant would tell us whether the bias is baked at pre-training or accumulates from RLHF.
4. **What replaced the em dash in human writing during the same era.** As AI use rose, did human prose shift away from em dashes to preserve voice? A longitudinal corpus study of New Yorker articles from 2018 to 2026 would surface the answer.
5. **Effect on reader trust.** Does em-dash density correlate with perceived AI authorship in blind reader studies? If the correlation is strong, the em dash is genuinely functioning as an AI tell. If weak, the community signal has overshot its empirical basis.

## A small claim about craft

The reason this matters beyond mild annoyance is that punctuation is part of voice. Voice is what distinguishes prose someone wrote from prose generated to fit a pattern. When AI-assisted writing arrives in a creative-craft context, the typographic tells are the first signal that something has been smoothed. The em dash, used too often, flattens specificity. Each individual instance might fit; the cumulative effect is a register that floats above the writer's actual voice.

So the question of why AI loves em dashes is not really about typography. It is about why the model defaults to the average register rather than the specific one. The em dash is the symptom; the underlying issue is the absence of voice. The fix is not to ban the punctuation. The fix is to give the model a voice to reach for.

For Volley, the practical answer is the rule already written: use colons, semicolons, commas, parentheses, full stops. Em dashes are off the table. The reason for the rule is not typographic preference; it is voice protection. Every word, every mark, every typographic choice is the writer's. Letting the average creep in through the punctuation is the same as letting it creep in through the vocabulary or the rhythm. The bible's rule against em dashes is one of many small disciplines that, taken together, mean an artist or a player or a contributor reading Volley's writing reads Josh and the people he works with, not the average of the corpus.
