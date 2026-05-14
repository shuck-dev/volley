# Items

Design for the prototype's item set. Item effects are gameplay-first: the effect is immediately perceptible. The player figures out what an item does by owning it, not by reading a description. Most items are causality-driven; passive stat boosts are a subset of the same system.

The Tinkerer carries the narrative meaning of each item. The item itself just does its thing.

FP is the pre-break incentive currency. Post-break phases may introduce different objectives, so items designed for those phases may target different incentives entirely. Pre-break prototype items are FP-focused, but the framework must not assume FP is always the reward worth designing around. Items that carry across phases should stay useful under different objective conditions.

Implementation spec lives in [`../tech/05-items.md`](../tech/05-items.md). Effect-system framework lives in [`../tech/04-effect-system.md`](../tech/04-effect-system.md).

---

## Item design categories

Starting categories. Not exhaustive; new items may introduce new ones.

- **Consolation.** Rewards failure or loss. Softens the sting, gives the player something to hold onto after a miss. The Stray lives here.
- **Precision.** Rewards consistency and streak-building. Stat modifiers that scale with sustained play. The opposite of consolation: you earn it by not dropping the ball.
- **Field-changing.** Alters the play space or ball behaviour rather than the paddle or economy. Creates moments where the court itself feels different.
- **Slot-expanding (court).** Court items that expand kit capacity or provide always-on utility. Simple effects, big meta-progression value. Natural candidates for secret destruction unlocks.
- **Risk/reward.** Injects variance into the economy or gameplay. Chance-based or high-stakes tradeoffs where the player opts into uncertainty for a bigger payoff.
- **Momentum.** Snowball effects that build with sustained play. The longer you go, the bigger the payoff. A miss wipes everything. High ceiling, hard crash.
- **Recovery.** Helps you bounce back after a miss. Different from consolation (which rewards the miss itself); recovery is about getting back on track faster.
- **Defensive.** Makes it harder to miss. Bigger paddle, slower approach, second chances. The safety item.
- **Tempo.** Changes the rhythm of the game. Speeds up or slows down in patterns. The game breathes differently.
- **Synergy.** Weak alone, powerful when combined with specific other items. The build-around category.
- **Partner-enhancing.** Buffs your partner's play. Invests in the relationship, not just yourself.

---

## Authoring rules

Items are designed around a **thing + twist** formula. The thing is a physical object. The twist gives it character and hints at the gameplay without explaining it. The physical description is for art direction and may differ from the name and description text.

Descriptions are short, a fragment of thought from the main character's mind. No second person. Leave the narrative to the other characters.

Because descriptions are short they can change dynamically. Variant text is keyed to item state and swapped silently in the UI: no announcement, no tooltip. The player notices the text has shifted and understands why through play.

Every item has exactly 3 variants: default, item power revealed (triggers once the player has witnessed the effect), and narrative revealed (post-break for pre-break items; tied to the relevant story beat for post-break items).

Items have 3 levels: base (purchased), upgraded, max. Cost scaling lives with the effect blocks in [`../tech/05-items.md`](../tech/05-items.md).

Item card format:

```
Thing + twist | Physical description | Category (only if not Kit)
Name
Descriptions (state -> text)
Effects per level
Cost | Scaling
```

---

## Items

### The Stray

Lost ball + gunpowder. Worn ball dusted lightly in gunpowder, slightly singed around the seams.

| State | Description |
|---|---|
| Default | "Nobody trained it" |
| After frenzy triggers once | "Fast. Too fast" |
| Post-Break | "It was always going to do that" |

A miss spawns an extra ball (capped per level). A personal-best sets the court to frenzy: speed doubles, balls multiply, the next miss clears it all out.

### The Call

Referee card + shifting colour. Battered card, creased at the corners, colour different every time you glance at it.

| State | Description |
|---|---|
| Default | "Looks official" |
| After first colour change | "That wasn't green" |
| Post-Break | "Why wasn't I there?" |

Every n-th hit, the card flips to a random colour. Each colour sets the FP-per-hit multiplier until the next flip. Every flip also deflects the ball to a random angle. The player learns colours through play, not a legend.

Blue and Gold do not exist in refereeing. The card is showing calls that cannot exist.

### Dead Weight

Medicine ball + dense metal. Small, impossibly heavy, dull grey surface with no grip. The court sags slightly where it sits.

| State | Description |
|---|---|
| Default | "Don't try to move it" |
| After first gravity-warped hit | "Why does my hand look weird?" |
| Post-Break | "Still there" |

A gravity well sits on the court, curving ball trajectory toward it. Hits on faster balls earn bonus FP. At max level, the well surges when the ball passes behind a paddle.

### Spare

Training cone + melted base. Court item. Standard orange cone, base slightly warped like it was left in the sun too long. It doesn't move when you kick it.

| State | Description |
|---|---|
| Default | "There's always one left over" |
| After equipping 4th kit item | "Wasn't supposed to need it" |
| Post-Break | "Nobody noticed it was missing" |

Court item. Appears on the court in the background. Grants +1 kit slot. The bonus slot appears on the floor next to the kit bag in the kit UI, visually distinct from the base bag slots.

### Long Shot

Betting slip + race already ran. Crumpled slip, printed odds faded, creased from being folded and unfolded too many times.

| State | Description |
|---|---|
| Default | "Haven't checked yet" |
| After first roll resolves | "It was already decided" |
| Post-Break | "Held onto it this whole time" |

Each rally starts a hidden timer (random delay). If the timer fires before you miss, the slip rolls and an effect triggers. If you miss first, the race never finishes. Higher levels add outcomes to the table and tighten the delay window. All outcomes are equally weighted.

| Roll | Effect |
|---|---|
| **Payout** | FP burst |
| **Photo Finish** | Temporary ball speed boost |
| **Dead Heat** | Temporary paddle size increase |
| **False Start** | Ball speed immediately set to max |
| **Long Shot Pays** | All other positive effects fire simultaneously |

### Seven Years

Mirror + no end. Small rectangular locker mirror, scratched frame. Looks normal until you hold it at the right angle and the reflections don't stop.

**Whole:**

| State | Description |
|---|---|
| Default | "How deep does it go?" |
| Power revealed | "It's fine" |
| Post-Break | "Counted every one" |

**Broken:**

| State | Description |
|---|---|
| Default (just broke) | "Too late" |
| Power revealed (curse felt, or Tinkerer levels it) | "Sharper than before" |
| Post-Break | "Some things don't heal" |

Passive FP multiplier that scales with hidden crack count. Each miss adds a crack. The player never sees the number. More cracks means more fractal reflections, higher multiplier. At 100 cracks the mirror breaks and becomes a cursed item with a slight debuff. The broken state persists until dealt with.

Leveling fully repairs the mirror, resetting cracks to zero and the multiplier back to base. The player chooses when to level: push the cracked multiplier higher, or repair before it breaks.

True power is in synergy with other items (future design).

### Cadence

Whistle + out of tune. Standard coach's whistle, brass tarnished, plays a note that's slightly flat. You can feel it in your teeth.

| State | Description |
|---|---|
| Default | "Sounds wrong" |
| After first ceiling raise | "Don't stop. Won't stop" |
| Post-Break | "Was anyone listening?" |

The whistle sets the tempo. Ball speed oscillates in waves: ramping up and down unpredictably. When the ball reaches max speed, the ceiling raises and speed keeps climbing.

---

## Simple stat items

Passive stat modifiers. No triggers, no conditions, no twist. These exist so the shop has straightforward purchases available early: the player picks one, feels the difference immediately, and understands the economy before encountering causality items.

These are not build-around items. They are reliable, boring, and useful. The kind of thing you buy because you need it, not because it excites you. They round out a kit without competing for attention.

### Ankle Weights

Leg weights + worn elastic. Scuffed ankle weights, elastic fraying, sand shifting inside. They've been used every day for a long time.

| State | Description |
|---|---|
| Default | "Heavy steps" |
| Power revealed | "Didn't notice the difference until I took them off" |
| Post-Break | "Still wearing them" |

Increases paddle movement speed per level.

### Grip Tape

Sports tape + sticky residue. Roll of white grip tape, half used, end stuck to itself. Leaves marks on everything it touches.

| State | Description |
|---|---|
| Default | "Covers more than you think" |
| Power revealed | "Hard to miss now" |
| Post-Break | "Held it together" |

Increases paddle collision size as a percentage of current paddle size per level.

### Training Ball

Practice ball + always warm. Bright orange practice ball, slightly soft, always warm to the touch no matter how long it sits.

| State | Description |
|---|---|
| Default | "Already moving" |
| Power revealed | "Starts fast. Stays fast" |
| Post-Break | "Never cooled down" |

Raises the ball's starting speed per level.

### Court Lines

Chalk line + no end. Piece of court chalk, worn to a nub. The lines it draws keep going past where you stopped.

| State | Description |
|---|---|
| Default | "Wider than it looks" |
| Power revealed | "The ceiling keeps moving" |
| Post-Break | "Drew them everywhere" |

Raises the ball speed ceiling by increasing the max range above the minimum.

### Wrist Brace

Wrist brace + locked stiff. Rigid plastic brace, velcro frayed, joint locked at a fixed angle. It wasn't always this tight.

| State | Description |
|---|---|
| Default | "Can't bend it" |
| Power revealed | "Doesn't give" |
| Post-Break | "Locked for good" |

Cursed item. The locked joint stabilizes your swing, transferring more force per hit. But the rigidity restricts your range, narrowing the effective paddle surface. The same stiffness that gives you power takes away reach.

At equal levels with Grip Tape, the paddle size effects cancel out completely. The player gets the ball speed increment for free but no paddle growth. Levelling one ahead of the other tips the balance: Grip Tape ahead means a bigger paddle with faster hits, Wrist Brace ahead means a clamped paddle with much faster hits.
