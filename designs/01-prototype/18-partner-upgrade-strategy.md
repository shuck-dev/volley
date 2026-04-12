# Partner Upgrade Strategy

## Goal

Define how partners scale with the player's progression so that no partner becomes a bottleneck or obsolete as the game advances.

**Points:** Spike
**Dependencies:** Partner AI (`17-partner-ai.md`), First Partner Unlock (`11-first-partner-unlock.md`), Effect System (`07-effect-system.md`), Upgrade Shop (`04-upgrade-shop.md`)

## Problem

Partners read `ItemManager.get_base_stat(&"paddle_speed")` as their speed ceiling: the unupgraded base from `GameRules.BASE_STATS`. As the player upgrades their own paddle through items, their capability pulls ahead of the partner's. Without a way to close this gap, the partner becomes the limiting factor in every streak, which frustrates the player (see `17-partner-ai.md`, principle 1).

Early partners (Martha) don't have this problem because they arrive when the player has few or no upgrades. Both sides struggle at similar speeds. The problem emerges in mid-to-late game when the player's paddle is significantly upgraded and new partners arrive at base stats.

## Design: stat sharing as a prestige reward

The player's upgrades lift the active partner through stat sharing, delivered as a permanent upgrade from the Tinkerer's prestige system (SH-81). The player brings their full item loadout to the Tinkerer, who clears it in exchange for a permanent upgrade. Stat sharing is one of the options.

This means stat sharing is earned through a full cycle of play, not found in a shop rotation. The player has experienced the gap between their capability and the partner's, and they choose to close it.

### Why stat sharing

Partner-specific upgrades ("Martha's speed +10%") create two problems:
- They don't transfer. Recruiting a new partner resets progress.
- They create a parallel progression track that competes with the player's own upgrades for FP without feeding into the same system.

Stat sharing solves both:
- Every player stat upgrade also upgrades the partner (once the prestige reward is earned)
- New partners immediately benefit from existing stat sharing
- The player's investment in their own stats is never wasted; it lifts every partner
- The progression feels like "we're getting better together" not "I'm training one specific partner"

This fits the game's narrative: these are people you're playing alongside. Getting better together is the relationship.

### How it works

Stat sharing uses the existing `share_stats_with_partner` outcome type from the effect system. When stat sharing is active, the partner's effective stat becomes a blend: base value plus a share of the player's upgrade delta.

The AI config's three knobs (`reaction_delay_frames`, `speed_scale`, `noise`) remain fixed per partner. What changes is the speed ceiling the partner operates within. A partner with `speed_scale = 0.70` and a shared paddle speed of 600 px/s moves at 420 px/s effective, up from 350 px/s at base. The AI algorithm is unchanged; the input values shift.

### What gets shared

The primary stat to share is `paddle_speed`, because it directly determines the partner's physical ceiling (which balls are reachable). Other stats could be shared in future (paddle size, reaction improvements) but speed is the one that matters most for the miss profile.

Double Knot (level 3) shares all player stat buffs with the partner. This is the late-game power spike within a cycle. The prestige reward provides the permanent baseline that carries across cycles.

### Progression stages

**Early game (Martha, no prestige):**
The player has few upgrades. The partner is tuned to be reliable at base speeds. No gap exists because the player hasn't outgrown the partner. Stat sharing isn't needed.

**First prestige:**
The player has completed a full cycle and earned stat sharing as a permanent upgrade. Next cycle, player upgrades immediately lift the partner. The gap that opened in the previous cycle doesn't reappear.

**Later prestiges:**
Additional permanent upgrades compound. The partner scales with the player from the start of each cycle.

### No partner becomes obsolete

Because stat sharing applies to the active partner (not a specific partner), recruiting a new partner in a later phase doesn't reset progress. The new partner inherits the same shared stats from the moment they're recruited. Their personality comes from their AI config (different noise, reaction delay, speed scale) and their effects, not from a separate upgrade track.

### Court items and the shop

Court items (purchased once, always active, no kit slot cost) are a separate category from prestige rewards. They reset with everything else on prestige. The shop gains a 6th slot drawing from a dedicated court item pool, guaranteeing the player always has a court item available to buy.

Court items provide within-cycle benefits. Prestige rewards provide across-cycle permanent upgrades. Stat sharing is the latter.

## Design notes

**Stat sharing is additive, not replacement.** The partner's base stat + a share of the player's upgrade delta, not the player's full stat value. This preserves the partner's identity: a partner with `speed_scale = 0.70` is always slightly slower than the player, even with full sharing. The gap shrinks but never fully inverts.
