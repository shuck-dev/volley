# Volley Vendetta - Prototype Design

## Overview
Idle pong game. Two paddles volley a ball back and forth. Score counts volleys (paddle hits). No win condition for now — just keep the rally going. Player controls one paddle, second paddle is a wall for now (AI in future).

## Features (build order)

1. **Ball bouncing in arena** - DONE
   - RigidBody2D ball with speed clamping (min/max)
   - StaticBody2D walls with PhysicsMaterial (bounce=1.0, friction=0)

2. **Player paddle** - IN PROGRESS
   - RigidBody2D so ball physically pushes it (revolving door effect)
   - Player input: W/S or arrow keys
   - X position locked, free vertical movement and rotation
   - Linear damp for rotation settle-back

3. **Volley counter**
   - Detect when ball hits a paddle
   - Increment volley count on each paddle hit
   - Reset count when ball is missed (hits left/right wall)

4. **Volley UI**
   - CanvasLayer with Label showing current volley count
   - High score tracking (best streak)

5. **Second paddle (wall for now)**
   - Right wall stays as a wall initially
   - Later replaced with AI paddle

## Future features
- AI paddle (tracks ball, toggleable)
- Win/loss conditions
- Speed increases over time
- Power-ups / modifiers
- Idle progression (upgrades, auto-play)

## Architecture

### Pure logic classes (unit-testable)
| Class | File | Purpose |
|---|---|---|
| GameRules | `scripts/game_rules.gd` | Constants: speeds, thresholds |
| VolleyTracker | `scripts/volley_tracker.gd` | Volley count, high score, reset |

### Node scripts
| Class | Extends | File | Purpose |
|---|---|---|---|
| Ball | RigidBody2D | `scripts/ball.gd` | Ball physics, speed clamping |
| Paddle | RigidBody2D | `scripts/paddle.gd` | Player movement, rotation on hit |
| GameManager | Node | `scripts/game_manager.gd` | Volley tracking, UI updates |

### Scenes
```
scenes/
  main.tscn       - Arena with walls, paddle, ball, UI
  ball.tscn       - RigidBody2D + CircleShape2D + Sprite2D
  paddle.tscn     - RigidBody2D + RectangleShape2D (40x200) + Sprite2D
```

### Main scene layout
```
Node2D
  Camera2D
  GameManager
  TopWall       (StaticBody2D)
  BottomWall    (StaticBody2D)
  LeftWall      (StaticBody2D - becomes goal zone later)
  RightWall     (StaticBody2D - becomes AI paddle later)
  PaddleLeft    (paddle.tscn, player-controlled)
  Ball          (ball.tscn)
  UI (CanvasLayer)
    VolleyCount (Label)
    HighScore   (Label)
```

## Key design decisions

- **RigidBody2D for both ball and paddle** - allows physical interactions (ball pushes paddle, paddle rotates on impact)
- **Speed clamping** - physics engine doesn't perfectly conserve energy, so ball speed is enforced every physics tick
- **GameRules as constants class** - single source of truth for tunable values
- **Volley counting not scoring** - idle game measures sustained rallies, not goals
- **Paddle X-lock** - paddle stores initial X and resets it every frame to prevent lateral drift
- **Walls as placeholders** - right wall will become AI paddle in future iteration
