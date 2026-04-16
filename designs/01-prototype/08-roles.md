# Item Roles

Every item declares one of three roles. The role decides where it goes on the court, who owns its prop, and what gesture the player uses to move it.

**Dependencies:** Items (`08-items.md`), Venue (`08-venue.md`), ItemManager (`08-item-manager.md`), Fixtures (`08-fixtures.md`).

---

## The three roles

| Role | Holds | Example items |
|---|---|---|
| `ball` | Items that add a ball to the game | Training Ball, The Stray |
| `court` | Props on or around the court surface (always on court once acquired; removed only by Tinkerer) | Dead Weight, Spare, Court Lines, bot dock, jukebox, The Call |
| `equipment` | Items the main character wears or attaches to the paddle | Grip Tape, Double Knot, Wrist Brace, Ankle Weights, Cadence, Seven Years |

Stat-only items (no visible prop) still declare a role: a paddle-speed upgrade is `equipment`, a ball-bounce tweak is `ball`.

Ball and court roles are additive: any number of items can share the role. Equipment has a per-type cap: each item type (e.g. grip wrap, wrist brace) declares a maximum number that can be equipped at once. `move_to_court` rejects the item if equipping it would exceed the cap for its type.

```gdscript
const _ROLE_REGISTRY: Dictionary[StringName, StringName] = {
    &"ball":      &"additive",
    &"court":     &"additive",
    &"equipment": &"additive",
}
```

---

## Who hosts each role's prop

- **`ball`**: the ball rack hosts balls at rest; the court's ball manager hosts them in play. `BallReconciler` moves balls between the two in response to `court_changed` (see `08-balls.md`).
- **`equipment`**: the gear rack hosts equipment at rest; `paddle.tscn`'s attachment nodes (`Handle`, `Head`, etc.) host them when equipped. Parenting follows the scene; no fixture manager involvement.
- **`court`**: always on the court from acquisition. `FixtureManager` spawns the prop at the next free marker under `Roles/Court/` (see `08-fixtures.md`). Court items have no kit state; when dragged to the Tinkerer they sit in the workshop queue until returned to the court or destroyed.

Only `court` uses `FixtureManager`. Ball and equipment props move between two authored parents.

---

## Court marker resolution

Court items need authored world-space markers; ball and equipment do not.

```gdscript
func get_court_position(item_key: String) -> Vector2:
    var markers := _child_markers_for(&"court")
    var position_index := on_court[&"court"].find(item_key)
    position_index = mini(position_index, markers.size() - 1)
    return markers[position_index].global_position
```

Each court occupant takes the next marker; overflow stacks on the last.

---

## Placement flow

On `move_to_court(item_key)`:

1. Append to `on_court[role]`.
2. Register effects with `EffectManager`.
3. If `role == &"court"`, `FixtureManager` spawns the prop. For `ball` and `equipment`, the parent scene handles prop placement directly.
4. Emit `court_changed`.

Stat-only items skip step 3.

---

## Drag-and-drop

The player drags items between the kit and the court. Gesture details (live drag vs. step-off required) live in `08-kit.md`. The role system's part:

- The role is baked into the item, so a drop on the appropriate target always routes the move.
- A `RoleHighlighter` lights the target surface during drag (the court for ball, court markers for court-role props, the main character for equipment).

---

## Character areas vs item roles

Character areas (shop, workshop) are child scenes of `venue.tscn` gated by `unlocked_characters`. Roles are authored under `Roles/`, gated by item occupancy. They can sit near each other but are never parented under each other.

---

## Testing

- Occupancy: append, remove, overflow stacking on the last court marker.
- `get_court_position` returns the right marker per index.
- `court_changed` fires on each transition.
- A court item with no authored marker surfaces a clean error.

---

## Resolved questions

1. **Within-role conflicts.** Equipment uses a per-type cap. Each item type declares how many can be equipped simultaneously; `move_to_court` enforces it.
2. **Debug overlay.** Yes, behind a keypress. Shows role markers, current occupants, and equipment type caps.

---

## Rough ticket outline

Not filing yet.

1. Role registry on `ItemManager`.
2. `ItemDefinition.role` field; authoring pass across existing items.
3. `Roles/Court` markers in `venue.tscn`.
4. `get_court_position` resolver.
5. `RoleHighlighter` for drag feedback.
6. Dev-only role overlay.
