# Minified Paddle

## Goal

Define the paddle size range: a starting size that feels generous, a minimum size that feels punishing, and a visual change when the paddle hits its smallest form.

**Points:** Spike
**Dependencies:** Paddle (`scripts/entities/paddle.gd`), Grip Tape item (`design/items.md` and `tech/05-item-effects.md`)

## Current state

`paddle_size` and `paddle_size_min` are both 50.0 px. The paddle starts at its floor and can only grow. There is no concept of shrinking below the starting size, and no visual distinction at different sizes.

## Problem

Starting at the minimum creates two issues:

1. **No room to shrink.** Cursed items or future effects that reduce paddle size have nowhere to go. The paddle is already as small as it gets.
2. **First impression is the worst version.** A new player sees the smallest paddle the game offers. There's no sense of losing capability because they never had more.

## Design

### Paddle starts at level 1 size

The paddle's starting size is larger than the minimum. The player begins with a paddle that feels comfortable. Upgrades (Grip Tape) make it bigger. Negative effects (cursed items, prestige reset) can shrink it below the starting size, down to the floor.

| Stat | Value | Notes |
|---|---|---|
| `paddle_size` | 100.0 | Starting size. Feels comfortable at base ball speeds. |
| `paddle_size_min` | 50.0 | Unchanged. The absolute floor. |

These are tuning targets for the Make Fun pass. The key ratio is starting size to minimum: 2:1 means the paddle can halve before hitting the floor.

### Minified paddle: different sprite at minimum size

When the paddle reaches `paddle_size_min`, it switches to a distinct "minified" sprite. This signals to the player that they're at the bottom: the paddle looks different, not just smaller. The visual shift makes the floor feel like a state, not just a number.

The minified sprite should feel compressed, strained, like the paddle is holding on. Not broken (that implies non-functional), not comical (that undermines the tone). Think of it as the paddle at its most determined: still playing, but clearly struggling.

**When it activates:** The paddle is at or within a threshold of `paddle_size_min`. A small buffer (e.g. 5 px above the minimum) prevents flickering between sprites when size effects oscillate near the boundary.

**When it deactivates:** The paddle size rises above the threshold. The sprite reverts to the normal version, scaled appropriately.

### How the player gets here

The minified state is not part of normal early-game play. A new player starts at 100 px and grows from there. The minified paddle appears when:

- **Cursed items:** An item with a negative paddle size effect shrinks the paddle below starting size. The player chose to equip it.
- **Prestige reset:** After a Tinkerer prestige, item effects are cleared. If the player had Grip Tape boosting their size, they lose it and drop to base 100. They don't hit minimum unless a curse is also active.
- **Future effects:** Any temporary debuff that reduces paddle size (an opponent effect in battle mode, a challenge modifier, etc.).

The minified state is always a consequence of player choice or a temporary challenge, never a default.

### Sprite implementation

The paddle holds two sprite references: the normal sprite and the minified sprite. `_apply_size()` checks the current size against the threshold and swaps visibility. Both sprites scale with size as they do today; the minified sprite just has a different texture.

The threshold for swapping is `paddle_size_min + swap_buffer`, where `swap_buffer` is a small constant (e.g. 5 px) to prevent oscillation.

## Impact on existing systems

**Grip Tape:** Currently +140% per level on a base of 50. With a base of 100, the same percentage gives 240 at level 1 instead of 120. The percentage may need retuning, but the mechanic is unchanged.

**Paddle clamping:** `_apply_size()` already clamps to `[paddle_size_min, arena_height]`. No logic changes needed for the clamp itself; just the sprite swap addition.

**Partner paddle:** Partners read `paddle_size` from base stats (or shared stats with stat sharing). The same minified sprite logic applies to partner paddles if they can be shrunk.
