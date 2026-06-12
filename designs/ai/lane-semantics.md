# Linear Lane Semantics

How a Volley issue moves from idea to released, what each state means, and the two rules that keep the board honest. This is the single source. The agent memory and the Linear status descriptions both point here.

## The lane

An issue advances along one lane and never moves backward:

Vault, Ready, Dispatched, Challenged, Completed, Closed.

Two states sit off to the side. Triage holds incoming external work before it joins the lane. Retired holds work that was cancelled or superseded, so it leaves the lane sideways rather than reaching the end.

## What each state means

The order alone is not enough; each transition has a concrete trigger, and getting the trigger right is what matters.

**Vault** is the backlog: work to be done someday. **Ready** is work planned for a cycle, promoted by Josh, who owns cycle membership. **Dispatched** means an agent is actively working the issue. **Challenged** means the pull request is open and the work is up for review.

These two transitions are driven by the Shuck team's PR automations: a draft PR opening moves the issue to Dispatched, marking it ready-for-review moves it to Challenged. The automations only fire on a PR that Linear has linked to the issue, and because branches are GitHub-facing (no `SH-N`), that link is made by hand once the PR is up (see `.claude/skills/commits/SKILL.md`, "Issue references"). Link the PR, then the state follows it.

**Completed means the work merged.** That is the whole meaning. Merge is deliberately set to no-action in the team automations, so reaching Completed is a manual move (never a close trailer, which overshoots). Verification does not live here.

**Closed means the work was released to production** through the cycle release carnival. The carnival is itself the regression test, the gate that confirms nothing else broke before shipping. The release pipeline sets Closed; it is never a hand-move and never something a PR merge should reach.

Verification lives in the Ride, not on the issue. A Ride is Josh playtesting the merged build; a closed Ride is what certifies the merged work holds. The issue reaching Completed says it merged, and the Ride closing says it was confirmed. Those are two separate facts on two separate surfaces.

## The two hard rules

**Forward only.** Once an issue advances, it never moves to an earlier state, even when a rework cycle tempts a move back to Dispatched. The state records the most-advanced step the work has reached. The one genuine exception is regression: when a Ride or post-merge playtest catches an already-Completed fix breaking again, the issue reopens forward to Ready because the work is genuinely re-opened, not because a state was overshot.

**The branch name carries the issue number and drives the link.** The branch is `feature/<gh-number>-<slug>`; that is where the GitHub number lives and the one place it appears. The PR body and commits describe the change, and the Linear attachment link is made by hand after the PR opens. One number, one home, and Linear movement flows from the branch.

Why the branch is the number's only home: a GitHub action-verb ahead of a number (`closes #123`, `fixes`, `resolves`) hands GitHub the issue-close on merge, which carries the linked Linear issue all the way to Closed, falsely reading as released. A bare `#123` is harmless on merge, yet keeping every number in the branch makes the dangerous verb form one nobody reaches for. This is the convention that drifts: roughly one PR in four has historically tripped it, and each cleanup is manual, so the branch-home rule is what holds it steady.
