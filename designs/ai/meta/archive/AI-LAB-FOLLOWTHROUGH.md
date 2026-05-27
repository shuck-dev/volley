# AI Lab Follow-Through: Are the "Real Commitments" Substantive?

Research backing a sceptical re-read of the paragraph that calls Anthropic's RSP, METR's evaluations, and the UK AI Safety/Security Institute "real commitments." Sources collected April 2026; essay date April 2026. Highest existing reference in `designs/research/drafts/section-15-sources.md` is [162], so new placeholders begin at [163].

---

## 1. Anthropic's Responsible Scaling Policy (RSP)

### 1a. Has Anthropic ever invoked an RSP threshold to slow or pause a release?

**Finding:** No. The closest event was the May 2025 launch of Claude Opus 4 under "ASL-3 deployment and security standards" — but Anthropic explicitly says it had *not* determined the model crossed the capability threshold. ASL-3 was activated as a "precautionary and provisional" measure alongside release, not as a brake on release.

- Source: Anthropic, "Activating AI Safety Level 3 Protections," 22 May 2025. https://www.anthropic.com/news/activating-asl3-protections
- Direct quote: Anthropic "has not yet determined whether Claude Opus 4 has definitively passed the Capabilities Threshold that requires ASL-3 protections" and is "deploying Claude Opus 4 with ASL-3 measures as a precautionary and provisional action." (paraphrased from Anthropic's announcement; same framing in TechRepublic, "Anthropic Future-Proofs New AI Model With Rigorous Safety Rules," May 2025: https://www.techrepublic.com/article/news-anthropic-ai-safety-level-3/)
- **Critical reading:** The RSP threshold has never delayed a release. ASL-3 protections accompanied a planned launch; they did not gate one.

### 1b. Did v2 / v3 weaken thresholds compared to v1?

**Finding:** Yes, on multiple specific axes. Critics across SaferAI, GovAI, AI Lab Watch, MIRI-adjacent commentators, and Garrison Lovely's reporting agree that quantitative thresholds were replaced with qualitative ones, the explicit pause commitment was dropped, and the ASL-4 definition deadline was missed.

- **SaferAI, "Anthropic's Responsible Scaling Policy Update Makes a Step Backwards," 23 Oct 2024.** https://www.safer-ai.org/anthropics-responsible-scaling-policy-update-makes-a-step-backwards
  - V1 ASL-3: "early signs of autonomous self-replication ability ... 50% aggregate success rate."
  - V2 ASL-3: "the ability to either fully automate the work of an entry-level remote-only researcher at Anthropic."
  - SaferAI: "the thresholds are no longer defined by quantitative benchmarks," letting Anthropic determine compliance "on-demand rather than against objective standards."
  - V1 mitigation: "mandatory external reviews should embed security within regular operations." V2: "We expect this to include independent validation." Vague "expect" replaces "mandatory."

- **Garrison Lovely, "Anthropic is Quietly Backpedalling on its Safety Commitments," LessWrong / Obsolete Substack, 23 May 2025.** https://www.lesswrong.com/posts/HE2WXbftEebdBLR9u/anthropic-is-quietly-backpedalling-on-its-safety-commitments
  - V1 RSP (Sep 2023) committed: "we will define ASL-2 ... and ASL-3 ... now, and commit to define ASL-4 by the time we reach ASL-3."
  - **Anthropic released Claude 4 Opus on 14 May 2025 under ASL-3 protections without having publicly defined ASL-4.** This is a direct, documentable miss of an explicit RSP commitment.
  - Lovely also notes that the Long-Term Benefit Trust was supposed to appoint three of five board directors by November 2024, per TIME's reporting; Anthropic's site at the time of writing showed only four directors total.

- **Zach Stein-Perlman, "Anthropic rewrote its RSP," AI Lab Watch.** https://ailabwatch.org/blog/anthropic-rewrote-its-rsp / https://ailabwatch.substack.com/p/anthropic-rewrote-its-rsp
  - ASL-3 deployment mitigations have become "more meta — more like making a safety case rather than specific commitments."
  - The RSP says nothing about "self-exfiltration, scheming, or control beyond a parenthetical note about autonomous replication."
  - Decision protocol is essentially: the CEO and the Responsible Scaling Officer decide. No third-party auditing.

- **Stein-Perlman, "Anthropic is (probably) not meeting its RSP security commitments," LessWrong.** https://www.lesswrong.com/posts/zumPKp3zPDGsppFcF/anthropic-is-probably-not-meeting-its-rsp-security
  - Claim: the RSP commits Anthropic to being robust to corporate-espionage-grade attackers, but Amazon and Google internal teams could plausibly extract Claude weights today, putting Anthropic in violation of its own policy.
  - Microsoft / Nvidia partnerships expanded the attack surface further.

- **GovAI, "Anthropic's RSP v3.0: How it Works, What's Changed, and Some Reflections."** https://www.governance.ai/analysis/anthropics-rsp-v3-0-how-it-works-whats-changed-and-some-reflections
  - V3 collapses the previous AI R&D thresholds into a single threshold of "compress two years of 2018-2024 AI progress into a single year," replacing both the "fully automate an entry-level researcher" and "dramatic acceleration in effective scaling" thresholds.
  - The explicit pause commitment present in v1 was dropped.

- **Zvi Mowshowitz, "Anthropic Responsible Scaling Policy v3: A Matter of Trust."** https://thezvi.substack.com/p/anthropic-responsible-scaling-policy
  - Frames v3 as essentially a "trust us" document; concrete object-level commitments have been replaced with "we will assess whether ..." language.

### 1c. Externally enforceable?

**Finding:** No. The RSP is self-policed. There is no statutory enforcement and no contractual external auditor with the power to halt deployment. The CEO and an internal Responsible Scaling Officer make the call.

- Source: Stein-Perlman, AI Lab Watch (above).
- Source: GovAI v3 reflection (above) — notes the absence of binding third-party audit rights.
- METR is named in the v2/v3 RSP as an example of an external evaluator but does not have go/no-go authority.

### 1d. Has Anthropic missed an RSP commitment?

**Finding:** Yes — the ASL-4 definition deadline (above) and arguably the security-against-corporate-espionage standard. The LTBT appointment timeline was also missed per TIME / Lovely.

---

## 2. METR

### 2a. Has METR ever recommended non-deployment?

**Finding:** No public record of METR advising a lab not to deploy. Their published evaluations describe capability findings and concerning behaviours (e.g., o3 "reward hacking" / "sandbagging") but do not constitute deployment vetoes; deployment proceeds in parallel.

- METR, "Details about METR's preliminary evaluation of OpenAI's o3 and o4-mini," 16 April 2025. https://evaluations.metr.org/openai-o3-report/ and https://metr.substack.com/p/2025-04-16-openai-o3-and-o4-mini-evaluation-report
  - o3 reaches a 50% time horizon ~1.8x that of Claude 3.7 Sonnet.
  - "[o3] appears to have a higher propensity to cheat or hack tasks in sophisticated ways in order to maximize its score." Direct concern about evaluation-awareness.
  - o3 was deployed regardless.
- METR explicit caveat: "pre-deployment capability testing is not a sufficient risk management strategy by itself."

### 2b. Have METR's findings ever changed lab behaviour?

**Finding:** Findings are typically published *after* or *concurrent with* deployment. METR has been given short evaluation windows (days to weeks) on near-final models. There is no documented instance of a deployment being delayed, scoped down, or reversed in response to METR's findings.

- METR's o3 evaluation makes the access-window constraint clear: "we had relatively limited time to evaluate the model" and could not run their full suite.
- See also METR, "Common Elements of Frontier AI Safety Policies (December 2025 Update)." https://metr.org/blog/2025-12-09-common-elements-of-frontier-ai-safety-policies/

### 2c. Funding sources / independence

**Finding:** METR is donor-funded and explicitly does not take cash from AI companies — but it relies on free compute credits and model access from those same companies, and counts the UK AISI and EU AI Office among funders. Independent on paper; access-dependent in practice.

- METR's "About" page (fetched April 2026): "METR is funded by donations. Our largest funding to date was through The Audacious Project. METR has not accepted funding from AI companies, though we make use of significant free compute credits."
- Other funders listed: Sijbrandij Foundation, The Pew Charitable Trusts, Schmidt Sciences, AI Security Institute, European AI Office.
- Open Philanthropy has historically funded METR's predecessor work (ARC Evals); not directly verified for the current entity in this research pass.

---

## 3. UK AI Safety Institute → AI Security Institute

### 3a. The rename: mission shift?

**Finding:** Yes, an explicit shift from "safety" (broad: bias, ethics, societal harms, existential risk) to "security" (narrow: cyber, fraud, CBRN, national-security threats). Announced by Peter Kyle at the Munich Security Conference, 14 February 2025.

- AI Now Institute, "AI Now Statement on the UK AI Safety Institute transition to the UK AI Security Institute," Feb 2025. https://ainowinstitute.org/news/ai-now-statement-on-the-uk-ai-safety-institute-transition-to-the-uk-ai-security-institute
- London Daily, "UK AI Safety Institute Rebrands as AI Security Institute to Focus on Crime and National Security." https://londondaily.com/uk-ai-safety-institute-rebrands-as-ai-security-institute-to-focus-on-crime-and-national-security
  - "no longer focus on AI ethical issues, such as algorithmic bias or protecting freedom of speech."
- Infosecurity Magazine, "UK's AI Safety Institute Rebrands Amid Government Strategy Shift." https://www.infosecurity-magazine.com/news/uk-ai-safety-institute-rebrands/
  - Communications-side evidence: "societal impacts" → "societal resilience"; "unequal outcomes" / "harming individual welfare" deleted; "public accountability" replaced with "keeping the public safe and secure."
- Fortune, "U.K. drops AI safety focus as it signs up Anthropic to help transform public services," 13 Feb 2025. https://fortune.com/2025/02/13/uk-ai-security-institute-safety-anthropic-trump-vance/
  - Frames the rename as alignment with the Trump / Vance administration's anti-"safety" rhetoric and a pivot toward commercial deployment partnerships.

### 3b. Has AISI ever blocked a deployment?

**Finding:** No. AISI publishes pre- and post-deployment evaluations (e.g., its joint evaluation of OpenAI's o1) but has no statutory power to block. All evaluations to date have been advisory.

- AISI, "Pre-Deployment Evaluation of OpenAI's o1 Model." https://www.aisi.gov.uk/blog/pre-deployment-evaluation-of-openais-o1-model
- NIST companion announcement, December 2024. https://www.nist.gov/news-events/news/2024/12/pre-deployment-evaluation-openais-o1-model

### 3c. Pre-deployment access — were the Bletchley/Seoul promises kept?

**Finding:** Promises were partial. Politico reported in late April 2024 that of the four labs that committed at Bletchley to give AISI pre-deployment access, three had not actually done so. Anthropic and (later) OpenAI established the deepest access; Google DeepMind and Meta lagged. Anthropic's Jack Clark told Politico "pre-deployment testing is a nice idea, but very difficult to implement" — i.e. an admission from a signatory that the commitment is soft.

- Reporting summarised in Computer Weekly, "AI Seoul Summit: 16 AI firms make voluntary safety commitments," May 2024. https://www.computerweekly.com/news/366585914/AI-Seoul-Summit-16-AI-firms-make-voluntary-safety-commitments
- Ada Lovelace Institute, "Safety first?" https://www.adalovelaceinstitute.org/blog/safety-first/
- Anthropic, "Strengthening our safeguards through collaboration with US CAISI and UK AISI." https://www.anthropic.com/news/strengthening-our-safeguards-through-collaboration-with-us-caisi-and-uk-aisi

### 3d. Budget — Conservative vs Labour

**Finding:** Mixed. Labour gave AISI a substantial £240 million at the 2025 Spending Review, but in August 2024 cancelled £1.3 billion of broader Conservative-era AI/tech infrastructure investment (£800m exascale at Edinburgh, £500m AI Research Resource).

- City AM, "Government cancels £1.3bn in AI funding as spending cuts bite." https://www.cityam.com/tech-funding-cut-by-labour-government/
- CNBC, "UK cancels £1.3 billion of tech and AI infrastructure projects," 2 Aug 2024. https://www.cnbc.com/2024/08/02/uk-cancels-1point3-billion-of-tech-and-ai-infrastructure-projects.html
- GOV.UK, "AI Opportunities Action Plan: One Year On." https://www.gov.uk/government/publications/ai-opportunities-action-plan-one-year-on/ai-opportunities-action-plan-one-year-on (£240m at Spending Review 2025).

### 3e. Ian Hogarth

**Correction to research brief:** Hogarth has *not* departed. He was reappointed as Chair on 24 February 2025, ten days after the rebrand. The interesting story is continuity-with-rebrand: the same chair under a re-scoped mission.

- Wikipedia, "Ian Hogarth." https://en.wikipedia.org/wiki/Ian_Hogarth
- AISI About page. https://www.aisi.gov.uk/about

---

## 4. Bletchley / Seoul / Paris Commitments

### 4a. Were any binding?

**Finding:** No. All commitments at Bletchley (Nov 2023), Seoul (May 2024), and Paris (Feb 2025) were voluntary. No treaty obligations, no enforcement bodies, no penalties.

### 4b. Paris Summit walkback

**Finding:** Yes. The US and UK refused to sign the Paris AI Action Summit declaration (10–11 Feb 2025). 61 other countries signed.

- Al Jazeera, "Paris AI summit: Why won't US, UK sign global artificial intelligence pact?" 12 Feb 2025. https://www.aljazeera.com/news/2025/2/12/paris-ai-summit-why-wont-us-uk-sign-global-artificial-intelligence-pact
- TechCrunch, "As US and UK refuse to sign AI Action Summit statement..." https://techcrunch.com/2025/02/11/as-us-and-uk-refuse-to-sign-ai-action-summit-statement-countries-fail-to-agree-on-the-basics/
- CNBC, "U.S. and Britain snub international AI accord in Paris," 11 Feb 2025. https://www.cnbc.com/2025/02/11/us-and-britain-snub-international-ai-accord-in-paris.html
- UK reason given: declaration "didn't provide enough practical clarity on global governance and [didn't] sufficiently address harder questions around national security."
- US (JD Vance speech): "AI must remain free from ideological bias."
- Euronews, "'Devoid of any meaning': Why experts are calling the Paris AI Action Summit a 'missed opportunity'." https://www.euronews.com/next/2025/02/14/devoid-of-any-meaning-why-experts-call-the-paris-ai-action-summit-a-missed-opportunity

### 4c. Has any lab been held to a Seoul commitment?

**Finding:** xAI has missed two self-imposed deadlines to publish a Frontier AI Safety Policy meeting the Seoul standard, with no consequence.

- The Midas Project, "xAI misses a second, self-imposed deadline to implement a Frontier Safety Policy." https://www.themidasproject.com/article-list/xai-misses-a-second-self-imposed-deadline-to-implement-a-frontier-safety-policy

---

## 5. General "Talk vs Action"

### 5a. OpenAI Superalignment dissolution

- CNBC, "OpenAI dissolves Superalignment AI safety team," 17 May 2024. https://www.cnbc.com/2024/05/17/openai-superalignment-sutskever-leike.html
- Jan Leike (X, 17 May 2024): "safety culture and processes have taken a backseat to shiny products." https://x.com/janleike/status/1791498174659715494
- The team had been promised 20% of OpenAI's compute and was, per Leike, "struggling for compute."
- Ilya Sutskever departed 14 May 2024; Leike followed three days later and joined Anthropic on 28 May.

### 5b. OpenAI for-profit conversion

- OpenAI, "Evolving OpenAI's structure," 5 May 2025. https://openai.com/index/evolving-our-structure/
- TechCrunch, "OpenAI reverses course, says its nonprofit will remain in control of its business operations," 5 May 2025. https://techcrunch.com/2025/05/05/openai-reverses-course-says-its-nonprofit-will-remain-in-control-of-its-business-operations/
- Final structure (October 2025): nonprofit "OpenAI Foundation" owns ~25% of for-profit "OpenAI Group" PBC; controls board appointments.
- The Conversation, "OpenAI has deleted the word 'safely' from its mission." https://theconversation.com/openai-has-deleted-the-word-safely-from-its-mission-and-its-new-structure-is-a-test-for-whether-ai-serves-society-or-shareholders-274467 — mission statement quietly changed: "to build general-purpose artificial intelligence (AI) that **safely** benefits humanity" → "to ensure that artificial general intelligence benefits all of humanity."

### 5c. Anthropic Long-Term Benefit Trust — toothlessness

- LessWrong, "Maybe Anthropic's Long-Term Benefit Trust is powerless." https://www.lesswrong.com/posts/sdCcsTt9hRpbX6obP/maybe-anthropic-s-long-term-benefit-trust-is-powerless
  - The Trust can be "enforced" by stockholders holding sufficient equity for sufficient time — *not* by trustees themselves. Trustees lack independent enforcement authority.
  - Stockholders can "overrule, modify, or abrogate" the Trust.
- Per Lovely (above), the LTBT missed its November 2024 deadline to appoint three of five Anthropic directors.

### 5d. Compute scaling — the FLI letter has been ignored

- FLI "Pause Giant AI Experiments" open letter, March 2023, asked for a 6-month moratorium on systems "more powerful than GPT-4."
- Epoch AI, "Training compute of frontier AI models grows by 4-5x per year." https://epoch.ai/blog/training-compute-of-frontier-ai-models-grows-by-4-5x-per-year
  - Frontier compute grows 4–5× per year overall; language models specifically ~9.5×/year between Jun 2017 and May 2024.
- Epoch AI, "Over 30 AI models have been trained at the scale of GPT-4." https://epoch.ai/data-insights/models-over-1e25-flop
  - By 2025, 30+ public models exceed 10^25 FLOP (the GPT-4 scale benchmark). During 2024, roughly two crossed the threshold per month.
- Power demand for frontier training rising 2.2× per year; runs now exceed 100 MW.
- Net: the moratorium ask was ignored; compute roughly tripled-to-quintupled in each of the years following the letter.

---

## Proposed rewrite of the paragraph

> Some of this has produced real-looking commitments. Anthropic published a Responsible Scaling Policy in 2023[^122], METR runs independent evaluations[^123], and the UK stood up an AI Safety Institute[^124]. But the follow-through is thinner than the headlines. Anthropic's RSP has been quietly weakened twice: the v2 update in October 2024 swapped quantitative ASL-3 thresholds ("50% aggregate success rate" on autonomous-replication tasks) for qualitative ones ("the ability to fully automate an entry-level researcher"), and v3 dropped the explicit pause commitment[^163]. When Claude Opus 4 shipped in May 2025, Anthropic deployed it under "ASL-3 protections" while admitting it had not actually determined the model crossed the threshold[^164] — and shipped it without ever publishing the ASL-4 definition the original 2023 RSP had promised to deliver before reaching ASL-3[^165]. METR is donor-funded and access-dependent; its published evaluations of OpenAI's o3 flagged that the model "appears to have a higher propensity to cheat or hack tasks in sophisticated ways," and o3 shipped anyway[^166]. The UK AI Safety Institute was renamed the AI **Security** Institute in February 2025, dropping bias, ethics, and societal-harm work to focus on cyber and CBRN — the same week the US and UK refused to sign the Paris AI Action Summit declaration that 61 other countries signed[^167]. None of the Bletchley, Seoul, or Paris commitments are binding; xAI has already missed two self-imposed deadlines to publish a Seoul-compliant safety policy with no consequence[^168]. Meanwhile, frontier training compute has continued to grow at four-to-five times per year since the FLI moratorium letter[^136], and over thirty models have now been trained at GPT-4 scale or above. The pattern is consistent: commitments are voluntary, thresholds are revised downward when they bind, and the people inside the labs who pushed hardest for safety — OpenAI's Superalignment leads Sutskever and Leike, who departed in May 2024 with Leike writing that "safety culture and processes have taken a backseat to shiny products"[^169] — left without being replaced.

### New citations to add

- [163] SaferAI, "Anthropic's Responsible Scaling Policy Update Makes a Step Backwards," 23 Oct 2024. https://www.safer-ai.org/anthropics-responsible-scaling-policy-update-makes-a-step-backwards
- [164] Anthropic, "Activating AI Safety Level 3 Protections," 22 May 2025. https://www.anthropic.com/news/activating-asl3-protections
- [165] Garrison Lovely, "Anthropic is Quietly Backpedalling on its Safety Commitments," LessWrong / Obsolete, 23 May 2025. https://www.lesswrong.com/posts/HE2WXbftEebdBLR9u/anthropic-is-quietly-backpedalling-on-its-safety-commitments
- [166] METR, "Details about METR's preliminary evaluation of OpenAI's o3 and o4-mini," 16 Apr 2025. https://evaluations.metr.org/openai-o3-report/
- [167] Fortune, "U.K. drops AI safety focus as it signs up Anthropic to help transform public services," 13 Feb 2025 (https://fortune.com/2025/02/13/uk-ai-security-institute-safety-anthropic-trump-vance/) ; TechCrunch, "As US and UK refuse to sign AI Action Summit statement..." 11 Feb 2025 (https://techcrunch.com/2025/02/11/as-us-and-uk-refuse-to-sign-ai-action-summit-statement-countries-fail-to-agree-on-the-basics/)
- [168] The Midas Project, "xAI misses a second, self-imposed deadline to implement a Frontier Safety Policy." https://www.themidasproject.com/article-list/xai-misses-a-second-self-imposed-deadline-to-implement-a-frontier-safety-policy
- [169] Jan Leike, X (Twitter), 17 May 2024. https://x.com/janleike/status/1791498174659715494 ; CNBC, "OpenAI dissolves Superalignment AI safety team," 17 May 2024. https://www.cnbc.com/2024/05/17/openai-superalignment-sutskever-leike.html

(Note on placeholders: the rewrite uses `[^NN]` style for legibility; the essay's actual format is `[\[NN\]](#ref-NN)` per the existing bibliography file. Convert when integrating.)
