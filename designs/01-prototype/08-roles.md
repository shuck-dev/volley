# Item Roles

Every item declares one of three roles. The role decides where on the court it goes and how it's positioned.

**Dependencies:** Items (`08-items.md`), World (`08-world.md`), ItemManager (`08-item-manager.md`), Fixtures (`08-fixtures.md`).

---

## The three roles

| Role | Holds | Example items |
|---|---|---|
| `ball` | Items that add a ball to the game | Training Ball, The Stray |
| `court` | Props on or around the court surface | Dead Weight, Spare, Court Lines, bot dock, jukebox, The Call |
| `equipment` | Items the character wears or attaches to the paddle | Grip Tape, Double Knot, Wrist Brace, Ankle Weights, Cadence, Seven Years |

Stat-only items (no visible prop) still declare a role — a paddle-speed upgrade is `equipment`, a ball-bounce tweak is `ball`.

All three roles are additive: any number of items can share a role. Within-role conflicts (two grip wraps on the handle) are an open question deferred to when a second conflicting item ships.

```gdscript
const _ROLE_REGISTRY: Dictionary[StringName, StringName] = {
    &"ball":      &"additive",
    &"court":     &"additive",
    &"equipment": &"additive",
}
```

---

## Positioning

Each role resolves positions differently:

- **`ball`** — ball fixtures spawn from the arena's single ball-spawn origin. `BallReconciler` (see `08-balls.md`) reconciles live balls against `on_court[&"ball"]`.
- **`equipment`** — equipment fixtures parent under named attachment nodes on `paddle.tscn` (e.g. `Handle`, `Head`). Position comes from the paddle's composition.
- **`court`** — court fixtures spawn at authored markers under `Roles/Court/` in `court.tscn`. Each occupant takes the next marker; overflow stacks on the last.

Only `court` needs authored world-space markers.

```gdscript
func get_court_position(item_key: String) -> Vector2:
    var markers := _child_markers_for(&"court")
    var position_index := on_court[&"court"].find(item_key)
    position_index = mini(position_index, markers.size() - 1)
    return markers[position_index].global_position
```

---

## Placement flow

On `move_to_court(item_key)`:

1. Append to `on_court[role]`.
2. Register effects with `EffectManager`.
3. If the item has a fixture, `FixtureManager` spawns it (see `08-fixtures.md` for where each role's fixture parents).
4. Emit `court_changed`.

Stat-only items skip step 3.

---

## Drag-and-drop

The player carries items between the kit and the court; the role is baked into the item, so a drop on the court always routes to the item's role. A `RoleHighlighter` lights target markers during carry.

---

## Character areas vs item roles

Character areas (shop, workshop) are child scenes of `court.tscn` gated by `unlocked_characters`. Roles are authored under `Roles/`, gated by item occupancy. They can sit near each other but are never parented under each other.

---

## Testing

- Occupancy: append, remove, overflow stacking on the last court marker.
- `get_court_position` returns the right marker per index.
- `court_changed` fires on each transition.
- Role cooldown timing.
- A court item with no authored marker surfaces a clean error.

---

## Open questions

1. **Within-role conflicts** (two grip wraps, two handle-hung weights). Options: `conflicts_with` list, tags, or per-item sub-slot keys. Decide when a second conflicting item ships.
2. **Debug overlay** for role markers and occupants. Leaning yes, behind a keypress.
3. **Role cooldown: per role or per item?** Per role.

---

## Rough ticket outline

Not filing yet.

1. Role registry on `ItemManager`.
2. `ItemDefinition.role` field; authoring pass across existing items.
3. `Roles/Court` markers in `court.tscn`.
4. `get_court_position` resolver.
5. `RoleHighlighter` for carry feedback.
6. Dev-only role overlay.
