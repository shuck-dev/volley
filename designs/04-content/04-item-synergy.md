# Item Synergy Design

Spike output for item synergy principles. Defines how items signal their partnerships through gameplay rather than UI.

---

## Core principle

Two items that go together should already make a good combo. The effects themselves tell the story. No tooltip, no wiki, no guide required. The player discovers the synergy by owning both items and noticing how they interact.

Synergies are deferred to Beta for full implementation (see `04-upgrade-shop-mechanics.md`), but the prototype item set should already hint at partnerships through its buff/debuff structure.

---

## Buff hinting

If a cursed item penalises a stat, there should be a natural partner that buffs the same stat through the same modifier type. The player who buys both feels clever because the effects made it obvious.

**Example: Grip Tape + Wrist Brace.** Grip Tape adds +140% paddle size per level. Wrist Brace subtracts -140% paddle size per level but adds ball speed increment. At equal levels they cancel on paddle size, giving the player faster ball acceleration for free. The player discovers this by owning both: the paddle stays the same size but hits start ramping harder.

The hint is in the stat itself. A player who notices their paddle shrinking from Wrist Brace will naturally look for something that grows it. Grip Tape is already in the shop. The connection is immediate.

---

## Design rules

- Every cursed item's penalty stat should overlap with at least one other item's buff stat
- The overlap should use the same modifier operation (percentage cancels percentage, add cancels add) so the interaction is clean and predictable
- The combo should be stronger than either item alone, but not mandatory: a player who only owns the cursed item should still have a viable (if harder) playstyle
- Synergy partners do not need to be in the same shop pool, but paired gravity (see `04-upgrade-shop.md`) will nudge them toward appearing together once one is maxed

---

## Prototype pairs

| Cursed item | Penalty | Natural partner | Buff | Interaction |
|---|---|---|---|---|
| Wrist Brace | -140% paddle size | Grip Tape | +140% paddle size | Cancel paddle size, keep ball speed increment |

Future pairs will follow the same pattern as the item set expands.
