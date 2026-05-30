# Dispatcher Focus and Work in Progress

A dispatcher gets more done by capping the threads it actively holds open, not by working single-threaded. The cap is on the orchestrator's own attention, the items it is coordinating in its head at once. Parallelism does not suffer; it moves to the worker layer through fan-out, where many delegated agents run at the same time. The rule is two-layered: keep orchestrator work-in-progress low, keep worker parallelism high.

This note collects the evidence, because the temptation to keep many items half-open feels like progress and is the opposite.

## The throughput math

Little's Law states that average work-in-progress equals throughput times average cycle time. With throughput fixed by real capacity, cycle time rises in direct proportion to work-in-progress: every extra open item lengthens how long each one takes to land. A board full of started-but-unfinished work ships slower than the same work driven to done one at a time. The Theory of Constraints (Goldratt) sharpens it: throughput is set by the single slowest component, so piling work in front of the bottleneck inflates lead time without raising output. The Kanban practice that follows is the slogan of Arne Roock's *Stop Starting, Start Finishing* (Lean-Kanban University, 2012): limit work-in-progress, finish before you start.

## The switching tax

The coordinator pays a personal tax for every concurrent thread. Gerald Weinberg's *Quality Software Management: Systems Thinking* (1992) gives the often-cited table: one project takes 100% of the time on it, two drops to 80% each as 20% leaks into switching, three to 60% each, and five or more leaves under a quarter per project. (The table is reproduced widely; it is worth confirming against the primary text before quoting as exact.)

The mechanism is real in the lab. Rubinstein, Meyer and Evans, "Executive Control of Cognitive Processes in Task Switching" (*Journal of Experimental Psychology: Human Perception and Performance*, 2001), measured switching cost rising with task complexity and unfamiliarity. The popular "up to 40% of productive time" figure is not in that paper; it is Meyer's later estimate quoted by the APA, and should be attributed to him, paired with the paper's actual finding rather than presented as the study's result.

Sophie Leroy's "attention residue" (*Organizational Behavior and Human Decision Processes*, 2009) is the most directly useful: switching leaves part of your attention stuck on the prior task, and an unfinished task leaves more residue than a finished one. Driving work to done before pulling the next item is the measured lower-cost path, not merely tidiness.

## Flow and single-piece flow

Csikszentmihalyi's flow (1990) requires concentration on a limited field with attention fully absorbed, which multitasking forecloses because all the attention is already spent. Lean's single-piece flow makes the throughput case in miniature: five one-minute stations deliver the first finished unit in five minutes one-piece, against 250 minutes for a batch of fifty. Same total work, time to first done of five minutes against 250.

## The delivery data

This is not manufacturing folklore. *Accelerate* (Forsgren, Humble and Kim, 2018) and the annual DORA reports find that elite software teams ship in small batches, the work-in-progress discipline applied to deployment, and that small batch size drives deployment frequency and lead time up without hurting stability. Low in-flight work buys speed and stability together rather than trading one for the other.

## Fan-out is the parallelism, not its enemy

None of this argues against running work in parallel. It argues against the *orchestrator* running it in parallel inside one head. The parallelism belongs at the worker layer.

Anthropic's account of its multi-agent research system describes an orchestrator-worker design, a lead agent that decomposes a problem and spawns parallel subagents with separate context windows, and reports it outperforming the single-agent baseline by 90.2% on their internal breadth-first research evaluation. The lead agent's contribution is clean decomposition and delegation, not doing the parallel work itself. The MAST taxonomy of multi-agent failures, meanwhile, attributes most production failures to specification ambiguity, the orchestrator under-specifying a handoff. Both are already cited in [`swarm-architecture.md`](swarm-architecture.md). Together they make the point precisely: a low-work-in-progress orchestrator is what makes each fan-out brief sharp, and a sharp brief is what makes the parallel worker succeed.

## What the evidence implies

The four veins converge: a dispatcher's throughput is set by how many threads it holds open, not by how hard it pushes each one. The numbers are stark. Little's Law makes every extra open item lengthen the rest; Weinberg's table puts the coordinator under half-useful work per thread past three concurrent threads; Leroy isolates the unfinished thread, specifically, as the one that degrades the next decision. And the breadth a mission needs sits at the worker layer rather than in the orchestrator's head, which is what fan-out delivers. The operational rule this implies lives in the dispatch skill ([`.claude/skills/dispatch/SKILL.md`](../../.claude/skills/dispatch/SKILL.md), "Focus and WIP"); this note is the evidence behind it.

## Sources

- Little's Law: [Caroli.org](https://caroli.org/en/little-law-cycle-time-and-throughput/), [Businessmap](https://businessmap.io/continuous-flow/littles-law).
- Theory of Constraints: [Lean Enterprise Institute](https://www.lean.org/the-lean-post/articles/what-is-the-theory-of-constraints-and-how-does-it-compare-to-lean-thinking/).
- Arne Roock, *Stop Starting, Start Finishing* (Lean-Kanban University, 2012); David Anderson, *Kanban* (2010).
- Gerald Weinberg, *Quality Software Management: Systems Thinking* (1992).
- Rubinstein, Meyer & Evans, "Executive Control of Cognitive Processes in Task Switching," *J. Exp. Psych: HPP* 27(4), 2001 ([PubMed](https://pubmed.ncbi.nlm.nih.gov/11518143/)); the 40% figure via [APA](https://www.apa.org/topics/research/multitasking).
- Sophie Leroy, "Why is it so hard to do my work?" *OBHDP* 109(2), 2009.
- Csikszentmihalyi, *Flow* (1990); Lean single-piece flow ([Process Street](https://www.process.st/one-piece-flow/)).
- Forsgren, Humble & Kim, *Accelerate* (2018); [DORA 2024](https://dora.dev/research/2024/dora-report/).
- Anthropic, "How we built our multi-agent research system"; MAST taxonomy: both linked from [`swarm-architecture.md`](swarm-architecture.md).
