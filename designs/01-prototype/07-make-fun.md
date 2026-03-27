# Make Fun Pass

## Goal
Run the complete prototype as a player and validate that the core loops are actually fun before moving to v0.5. This is a structured playtest and tuning pass — not a feature sprint. No new features ship here. Things that feel bad get fixed.

**Points:** 3 (tuning and iteration)
**Dependencies:** All prototype features complete (HUD Pass, Ball Scaling, Progression System, Idle Play, First Partner Unlock, Desktop Experience)
**Unlocks:** v0.5 Early Access (the prototype is declared done and fun is considered proven enough to share)

---

## Play goals

These are the three things the prototype must deliver. Everything in this pass is tested against them.

### 1. Active play feels worth doing for 10 minutes
The player picks up the paddle, keeps a streak going, and wants to keep going. The difficulty ramp from ball scaling should create tension without feeling unfair. When the streak ends, the player's first thought should be "I need to upgrade" — not "that was random."

### 2. The idle loop delivers on "come back to good news"
Player leaves the game running or closes it. When they return, something is waiting: FP earned, a milestone approaching, a streak that ended naturally. The return moment should feel like a small reward, not a chore to process.

### 3. Upgrades make a noticeable difference
After spending FP and upgrading, the player feels the change immediately. Paddle is faster, bigger, or the ball starts slower — something concrete shifts. The loop of "struggle → upgrade → feel good → hit a new wall → upgrade again" should complete at least once in a single session.

---

## Playtest sessions

Run each session with fresh eyes, no dev shortcuts.

### Session A — Cold start (10 minutes active)
Start a fresh save. Play actively for 10 minutes without touching the upgrade shop.

What to observe:
- Is the starting difficulty appropriate? Can a new player keep a 5+ volley streak in the first minute?
- Does the ball scaling feel gradual or sudden?
- Is there a natural moment where the player wants to open the shop?
- Does 10 minutes feel too long, too short, or right?

### Session B — Upgrade loop (until first wall hit)
Start from Session A save. Buy the first upgrade, play until the streak noticeably outpaces the upgrade, buy again.

What to observe:
- Does each upgrade feel impactful or marginal?
- Is the FP curve right? (Too fast = upgrades feel trivial. Too slow = player gives up before buying anything.)
- Do the three upgrade choices (speed, size, ball start speed) feel meaningfully different?
- Is there a moment where the player thinks "I know what I want next"?

### Session C — Idle and return
Leave the game running for 30 minutes (active window, no input). Return and review.

What to observe:
- Is the auto-play AI competent enough to earn FP but not so good it trivialises active play?
- Is the FP earned in 30 minutes idle proportionate to active play?
- Does the gap between idle FP rate and active FP rate create a reason to jump in?

### Session D — Offline return
Close the game. Wait at least 2 hours. Reopen.

What to observe:
- Does the welcome back screen feel like a gift?
- Is the offline FP amount satisfying without feeling broken?
- Is the return-to-gameplay flow smooth? (No friction before you see the ball bouncing again.)

---

## Tuning targets

These are the numbers most likely to need adjustment. Change one at a time, replay the relevant session.

| Variable | File | What it affects | Warning signs |
|---|---|---|---|
| Ball speed increment per hit | `ball.gd` / `GameRules` | Tension ramp, natural streak ceiling | Too fast: streaks always end at ~10. Too slow: ball never feels threatening. |
| FP per hit (base) | `game.gd` | Time to first upgrade | Too high: upgrades feel trivial. Too low: player quits before buying anything. |
| Upgrade cost scaling multiplier | `UpgradeDefinition` | Progression pacing | Too steep: second upgrade takes forever. Too flat: all upgrades gone in one session. |
| Upgrade effect per level | `UpgradeDefinition` | Upgrade impact | Too small: player can't feel the difference. Too large: game becomes trivial fast. |
| Idle FP rate (% of active) | `idle_play.gd` | Reason to play actively | Too high: active play not worth it. Too low: idle feels pointless. |
| Offline earnings cap (hours) | `progression_data.gd` | Return reward size | Too high: feels broken. Too low: returning after a day feels bad. |
| Auto-play miss rate | AI constants | Idle streak length | Too accurate: idle earns too much. Too clumsy: idle feels broken. |

---

## Exit criteria

The prototype is done when all three play goals are met:

- [ ] A player unfamiliar with the game (or you, after a week away) can pick it up and have a satisfying 10-minute active session without guidance
- [ ] Leaving the game for 2+ hours and returning produces a moment that feels good, not neutral
- [ ] The upgrade loop completes naturally in a 20-minute session (spend FP, feel improvement, hit a new wall, want to upgrade again)

If any criterion fails after tuning, identify the root cause and fix it before declaring the prototype done. This is the gate before v0.5.

---

## What this pass is not

- Not a bug fix sprint (bugs blocking play goals are in scope; everything else is not)
- Not a polish pass (animations, art, audio quality are v0.5 work)
- Not a balance pass (deep economy tuning is in v0.5 — Balance Pass. This is just "is it fun at all?")
