# Partner Upgrade Strategy

## Goal

Define how partners scale with the player's progression so that no partner becomes a bottleneck or obsolete as the game advances.

**Points:** Spike
**Dependencies:** Partner AI (`17-partner-ai.md`), First Partner Unlock (`11-first-partner-unlock.md`), Effect System (`07-effect-system.md`), Tinkerer Prestige (SH-81)

## Problem

Partners read `ItemManager.get_base_stat(&"paddle_speed")` as their speed ceiling: the unupgraded base from `GameRules.BASE_STATS`. As the player upgrades their own paddle through items within a cycle, their capability pulls ahead. Without a way to close this gap permanently, the partner becomes the limiting factor in every streak.

Early partners (Martha) don't have this problem. Martha arrives when the player has few or no upgrades; both sides struggle at similar speeds. The problem emerges across cycles: the player prestiges, starts a new cycle with permanent upgrades making them stronger, but the partner is still at base stats.

## Solution: stat sharing through prestige

Stat sharing is a permanent upgrade earned from the Tinkerer's prestige system (SH-81). When the player prestiges, they choose a permanent upgrade from a small selection. Stat sharing is one option. Once chosen, the player's stat upgrades lift the active partner for all future cycles.

### Why stat sharing over partner-specific upgrades

Partner-specific upgrades ("Martha's speed +10%") have two problems:
- They don't transfer. Recruiting a new partner means the investment is wasted.
- They create a parallel progression track competing with the player's own upgrades for FP.

Stat sharing avoids both. Every investment in the player's own stats also invests in every current and future partner. The progression feels like "we're getting better together."

### What gets shared

The primary stat is `paddle_speed`, because it directly determines the partner's physical ceiling: which balls are reachable. Other stats (paddle size, reaction improvements) could be shared in future, but speed is the one that matters for the miss profile.

The existing `share_stats_with_partner` outcome type in the effect system handles the mechanics. Double Knot (level 3) already uses this to share all player stat buffs within a cycle. The prestige reward provides the permanent baseline that carries across cycles.

### How it affects the AI

The AI config's three knobs (`reaction_delay_frames`, `speed_scale`, `noise`) remain fixed per partner. What changes is the speed ceiling the partner operates within. A partner with `speed_scale = 0.70` and a shared paddle speed of 600 px/s moves at 420 px/s effective, up from 350 px/s at base. The AI algorithm is unchanged; the input values shift.

Stat sharing is additive: the partner's base stat + a share of the player's upgrade delta, not the player's full stat value. `speed_scale` is applied after sharing.

Example: base paddle speed is 500, the player upgrades to 600 (delta of 100). With full stat sharing, the partner's effective base becomes 500 + 100 = 600. With `speed_scale = 0.70`, the partner moves at 600 x 0.70 = 420 px/s. Without sharing, the partner would be 500 x 0.70 = 350 px/s. The partner is always slightly slower than the player (who moves at the full 600), preserving their identity while closing the gap.

## Progression stages

**First cycle (no prestige yet):**
Martha arrives at base stats. The player has few upgrades. Both struggle at similar speeds. No stat sharing needed. Martha's effects (+25% FP, `halve_streak`) make her a net positive regardless.

**First prestige:**
The player completes a cycle, visits the Tinkerer, and chooses stat sharing as their permanent upgrade. Next cycle, every paddle speed upgrade the player buys also lifts the partner. The gap that opened in the previous cycle doesn't reappear.

**Later prestiges:**
Additional permanent upgrades compound. The partner scales with the player from the start of each cycle. New partners recruited in later phases immediately benefit from existing stat sharing.

## No partner becomes obsolete

Stat sharing applies to the active partner, not a specific one. Switching partners or recruiting a new one doesn't reset progress. Each partner's personality comes from their AI config (different noise, reaction delay, speed scale) and their effects, not from a separate upgrade track.

## Court items

Court items (purchased once, always active, no kit slot cost) are a separate category. They provide within-cycle benefits and reset on prestige like all other items. The shop gains a 6th slot drawing from a dedicated court item pool, so the player always has a court item available to buy without crowding the main rotation.

Court items are not the delivery mechanism for permanent upgrades. That role belongs to the prestige system.

The 6th slot is a shop system change that affects rotation logic, UI layout, and economy balance. It needs its own design work, likely as part of the Tinkerer prestige spike (SH-81) or a separate shop revision ticket.
