# Multiplayer Foundation

## Goal

Lay the architectural foundation for local and online multiplayer during Alpha, so that all game logic written from this point forward is multiplayer-ready. The actual multiplayer modes ship in Content Updates, but the state management pattern that makes them possible goes in now.

**Dependencies:** Prototype complete (core gameplay loop working)
**Unlocks:** Local Multiplayer (Content Updates), Online Multiplayer (Content Updates)

---

## Why Alpha, not later

Every state mutation in game.gd today is a direct assignment: `_volley_count += 1`, `_item_manager.add_friendship_points(points)`. Online multiplayer needs these mutations to flow through a command/event system so they can be serialised, replicated, and rolled back.

The longer this refactor waits, the more code needs retrofitting. In Alpha the codebase is still small and the core loop is stable. All new game logic written after this (Content Updates items, milestones, act system, Post-Break mechanics) will be built on the multiplayer-ready foundation from day one.

Local multiplayer does not strictly need this foundation (it can share a physics world directly), but building both modes on the same architecture avoids maintaining two state management patterns.

---

## Scope: what goes in Alpha

### Command/event pattern for state mutations

All gameplay state changes go through a central event bus or command system instead of direct mutation. This means:

- Paddle hit, ball miss, FP earned, item purchased, volley count changed: all expressed as commands/events
- Game state is reconstructed from the event stream
- Single-player mode runs the same command path with no network layer; zero overhead when playing alone

This is not a full ECS or networking framework. It is a thin layer that makes state changes explicit and replayable.

### Input abstraction

The current input system uses `Input.get_axis("paddle_up", "paddle_down")` directly in paddle.gd. For multiplayer:

- Each paddle reads from a player-specific input source
- Local multiplayer: different input actions per player (WASD vs arrows)
- Online multiplayer: remote player's input arrives via network and is injected into the same interface
- Single-player: unchanged, one player input source

### Second paddle support

The scene structure supports a second paddle on the opposite side. The back wall becomes optional (replaced by player 2's paddle in multiplayer, present in single-player). This is a scene configuration change, not a code architecture change.

---

## Scope: what ships in Content Updates

- **Local multiplayer mode**: two paddles, same SubViewport, split input, scoring and win conditions
- **Online multiplayer mode**: netcode layer on top of the command/event system, matchmaking, latency compensation
- **Multiplayer UI**: lobby, player indicators, score display

---

## Architecture overview

```
Input Sources
  PlayerInput (local keyboard/controller)
  RemoteInput (network, online only)
      |
      v
Command Bus
  PaddleHitCommand, BallMissCommand, PurchaseCommand, etc.
      |
      v
Game State
  Authoritative state, reconstructable from command history
      |
      v
Replication (online only)
  Commands serialised and sent to remote player
  Remote commands received and applied locally
```

In single-player and local multiplayer, the command bus is just a function call with no serialisation. The pattern exists so that online can plug in without changing game logic.

---

## What this means for current code

### game.gd changes

Before (current):
```gdscript
func _on_paddle_hit() -> void:
    _volley_count += 1
    _accumulate_friendship_points()
```

After (Alpha):
```gdscript
func _on_paddle_hit(player_id: int) -> void:
    execute(PaddleHitCommand.new(player_id))
```

The command handler does the same work, but the mutation is now an explicit object that can be logged, replicated, or rolled back.

### paddle.gd changes

Before (current):
```gdscript
var direction := Input.get_axis("paddle_up", "paddle_down")
```

After (Alpha):
```gdscript
var direction := _input_source.get_movement()
```

Where `_input_source` is injected: a `LocalInput` for single-player/local, a `RemoteInput` for online opponents.

---

## Online multiplayer approach

Two viable models, decision deferred to Content Updates design:

**Authoritative host**: one player's machine runs the simulation, the other sends inputs and receives state. Simpler, but the host has zero latency advantage.

**Rollback netcode**: both players simulate locally, exchange inputs, roll back and resimulate on disagreement. Better feel for fast-paced games like pong. More complex to implement but the command/event foundation makes it feasible.

The Alpha foundation supports both models. The choice is made when online multiplayer is designed.

---

## Open questions

- Should the command bus be a simple signal-based system or a proper command queue with history?
- How does the FP economy work in multiplayer? Shared pool, separate pools, or competitive?
- Does the shop (clearance) pause for both players, or can one player shop while the other plays?
- What are the win conditions for multiplayer? First to N points? Timed?
- Should online multiplayer use Godot's built-in MultiplayerAPI or a custom solution?
