# Shop Drag and Drop

## Goal
Implementation design for the Act 1 shop interaction: a Control-based drag and drop flow where the player moves items from the friend's things into a box to take them. Covers the structural shape of `shop.tscn`, the draggable `ShopItem` Control, the `TakeBox` drop target, and the new `ItemManager.take()` acquisition primitive that marks an item as owned without registering its effects.

**Dependencies:** Upgrade Shop (04-upgrade-shop), Item UI (05-item-ui), Venue (08-venue)

**Unlocks:** SH-32 acceptance criteria 6, 7, 8 (drag-and-drop, drag gating, purchase on drop). Tracked in SH-66.

**Status:** This document describes the **target** state. The shop as shipped in SH-32 is still Node2D-rooted with a Parallax2D background and a Camera2D. The Control restructure, the `TakeBox`, the drag-and-drop wiring, the `take` method, the display case overlay, and the friend's pick slot styling are all the responsibility of SH-66. Nothing described below has been built yet.

---

## Context

The shop is a secondary scene that `SceneLayout` opens alongside the running game. It is not an overlay. `shop.tscn` owns its own slice of screen and stays open while the game keeps running.

The current `shop.tscn` is Node2D-rooted with a Parallax2D background, a Camera2D, and a Table of `ShopItem` instances positioned in world space. That shape was a placeholder for the layout pass. It does not support Control-based drag and drop cleanly, because Control nodes do not live in 2D world space and the existing Node2D items cannot participate in Godot's built-in `_get_drag_data` / `_can_drop_data` / `_drop_data` protocol.

This document restructures the shop's interior to be Control-rooted while keeping it as its own scene, so the drag and drop interaction can use standard Godot UI.

---

## Interaction model

The player interacts with the shop by dragging items from a display row into a box. The interaction is diegetic: moving an object into a container, not selecting a menu option.

### Pick up
A draggable item responds to mouse-down with a drag start. Godot's Control drag and drop protocol handles the rest (cursor preview, hover feedback, cancellation).

The original item stays in its slot during the drag. It does not lift off or disappear. A translucent preview follows the cursor. On successful drop the `ShopItem` hides itself in place and the slot becomes an empty gap.

### Carry
The drag preview is a small rendering of the item's art scene, centred under the cursor, slightly translucent. It is built by the same SubViewport rendering path used by the inspector plugin and the `ShopItem` Control itself.

### Drop target
A single `TakeBox` Control receives drops. It is the only valid drop target in the scene. Dropping on any other Control, or outside all Controls, cancels the drag silently (Godot default behaviour).

The box has three visual states:
- **Idle**: neutral border and label ("Take")
- **Valid hover**: highlighted border, brighter label, during a drag over the box with a droppable item
- **Invalid hover**: not triggered in prototype, because unaffordable items cannot start a drag in the first place (see below)

### Release
On successful drop, the box calls `ItemManager.take(item_definition.key)`. The item is now owned, but its effects do not apply until the player equips it into the kit. Per 04-kit-and-locker, the kit is the active loadout and only kit items fire their causality and stat effects. The shop is the acquisition surface, not the equip surface: taking is "I want to keep this" and equipping happens later in the kit/locker UI. Where the item lives between acquisition and equip (the locker, in prototype) is the responsibility of the kit/locker UI, not of `take` itself.

The box emits an `item_taken(definition)` signal for future UI reactions (sound, flash, friend reaction animation).

On cancelled drop (released outside a valid target), nothing happens. No snap-back animation needed for prototype; Godot's default silent cancel is sufficient.

---

## Affordability and display cases

Per 04-upgrade-shop, affordability is communicated diegetically through a display case overlay, not through drag rejection. This keeps the fiction intact: the player does not see a "can't drop that" error, they see that the item is behind glass and their friend has not offered it.

**When an item is unaffordable:**
- The `DisplayCase` overlay on the `ShopItem` is visible and consumes mouse events. The item cannot be dragged and hovering it reveals nothing (no tooltip). The case is opaque to hover, matching "behind glass, you don't get to ask yet".
- Clicking a cased item plays a "tink" sound effect (tapping the glass), as diegetic feedback that the player tried to reach for something that is not yet offered. The sound is the only response.
- As a safety net, `ShopItem._get_drag_data()` also returns null when the item is unaffordable, so the drag still cannot start even if the case is hidden by a bug.

The display case has only two states in prototype: present or absent. It snaps in and out when affordability changes. A proper open/close animation is an art pass task.

**When the player's friendship crosses the threshold for an item:**
- `ItemManager.friendship_point_balance_changed` fires.
- Each `ShopItem` listens and toggles its `DisplayCase` visibility accordingly.
- The item becomes draggable on the next mouse-down.

**When an item is already taken:**
- `ItemManager.item_level_changed` fires.
- The `ShopItem` hides itself in place. The slot stays at the same index (so the friend's pick slot does not shift) but renders nothing and accepts no input. There is no "Taken" label and no tooltip.

---

## Scene structure

### shop.tscn (restructured)

```
Shop (Control, script = shop.gd)
├── Background (ColorRect)
├── Contents (VBoxContainer with margin padding)
│   ├── Header (HBoxContainer)
│   │   ├── TitleLabel ("Friend's Shop")
│   │   └── FriendshipLabel (right-aligned)
│   ├── ItemsRow (HBoxContainer)
│   │   └── ShopItem instances
│   └── TakeBox (PanelContainer, script = take_box.gd)
```

The Parallax2D background and Camera2D are removed. The Node2D `Table` is removed. The shop fills whatever Control space `SceneLayout` allocates to it. A `ColorRect` stands in as a plain backdrop until art replaces it. The `TakeBox` sits below the items row for prototype, spanning the full width so the player drags downward into it; exact placement is subject to change on the art pass.

The rightmost slot is visually distinguished as the friend's pick slot: a subtly different frame or background stylebox on the `ShopItem`. The rotation system that actually fills this slot with authored picks is out of scope for SH-66 (the prototype spawning logic continues to treat it as any other slot), but the visual cue lands now so the player sees one slot as more considered than the others from day one.

The current `Shop` script on the Node2D root is rewritten to extend Control instead. Its responsibilities remain: spawn items, update the friendship label, react to balance changes. It also flags the middle spawned item as the pick slot so the `ShopItem` applies the distinguished styling.

### shop_item.tscn (restructured)

```
ShopItem (Control, script = shop_item.gd)
├── ArtViewportContainer (SubViewportContainer)
│   └── ArtViewport (SubViewport)
│       └── [instantiated item_definition.art at runtime]
├── DisplayCase (Control with stylebox border, hidden when affordable)
└── Tooltip (instance of tooltip.tscn, hidden by default)
```

The art stays as a Node2D scene (the per-item scenes under `res://scenes/items/`). It is rendered inside a SubViewport the same way the inspector plugin renders it, except no `Camera2D` child: a SubViewport renders 2D content from the origin by default, and we just need a static fixed-size frame. If a particular item's art is not centred on its origin, the runtime `setup` adjusts the instantiated art's `position` to frame it inside the viewport. This is the canonical pattern: anywhere in the game that needs to show an item (shop, tooltip, future inventory, future collection screen), the item's Node2D art scene is rendered through a SubViewport owned by a Control wrapper.

There are no labels on the `ShopItem` itself. Name, cost, and flavour text only appear in the hover tooltip (the existing `tooltip.tscn`, which already has `NameLabel`, `CostLabel`, and `FlavorLabel`). For prototype this is the sole text affordance for items. The player sees the art on the table; hovering reveals the details. This keeps the visual composition diegetic (no UI text floating over the friend's things) and consistent with the diegetic framing in 04-upgrade-shop.

The current Node2D-based `ShopItem` (Sprite2D + Area2D + hover tooltip) is replaced entirely. Hover detection moves from `Area2D.mouse_entered` to Control's native `mouse_entered` / `mouse_exited` signals.

### take_box.tscn (new)

```
TakeBox (PanelContainer, script = take_box.gd)
├── Label ("Take")
```

Minimal. A panel with a visible border and a label. Drop target behaviour lives in the script.

---

## Scripts

### Forwarding pattern (extensibility constraint)

The Godot drag and drop virtual methods (`_get_drag_data`, `_can_drop_data`, `_drop_data`) are **thin forwarders**. They must not contain affordability logic, state checks, or side effects beyond dispatching to a named public method. The public methods form the stable contract that survives the move to a cross-window drag system in SH-51. This is not optional and not a stylistic preference: it is what makes the single-window implementation swappable without rewriting the shop.

The stable contract:

```gdscript
# ShopItem
func can_be_taken() -> bool
func build_drag_payload() -> ItemDefinition
func build_drag_preview() -> Control

# TakeBox
func can_accept(definition: ItemDefinition) -> bool
func accept(definition: ItemDefinition) -> void
```

The virtual methods call these and nothing else. See "Extensibility: multi-window drag" below for why.

### shop_item.gd (rewrite)

Extends `Control`. Keeps its `setup(definition)` and existing signal subscriptions. The Godot drag virtual method is a thin forwarder to the stable contract:

- `_get_drag_data(pos)` → returns null if `!can_be_taken()`, else calls `set_drag_preview(build_drag_preview())` and returns `build_drag_payload()`.
- `can_be_taken()` encapsulates the gating: definition present, level < max, player can afford.
- `build_drag_payload()` returns the `ItemDefinition`.
- `build_drag_preview()` instantiates the shared `item_dragging.tscn` helper (see below) and hands it the current `ItemDefinition`.

Display case visibility and tooltip text refresh from `ItemManager` signals. There are no labels on the item itself; the tooltip is the only text surface.

### item_dragging.tscn (new, shared)

A small throwaway Control used as the drag preview that follows the cursor during a drag. Extends `Control` and contains a SubViewport-based renderer of an `ItemDefinition.art` scene, sized and rendered to match the source's display size 1:1 so the lift feels seamless. Exposes a single `show_item(definition: ItemDefinition)` method.

This scene is shared across any drag source that shows an item being carried: `ShopItem` today, future `LockerItem` and `KitItem` tomorrow. Keeping it out of `shop_item.gd` avoids duplication when the kit/locker ticket adds its own drag sources.

### take_box.gd (new)

Extends `PanelContainer`. Thin forwarders over the stable contract:

- `_can_drop_data(pos, data)` → type-checks `data is ItemDefinition` and forwards to `can_accept`.
- `_drop_data(pos, data)` → forwards to `accept`.
- `can_accept(definition)` checks affordability and non-ownership.
- `accept(definition)` calls `ItemManager.take(key)` and emits `item_taken(definition)` on success.

The box never calls `ItemManager` directly from the Godot virtual methods; everything routes through `accept()` so tests and the future drag manager can drive it without a Viewport.

### shop.gd (rewrite to extend Control)

Unchanged in behaviour: spawns items, updates friendship label, exposes `preferred_width` for `SceneLayout`. Now extends Control and positions children via the `Contents` VBoxContainer instead of manual world-space positioning.

---

## Take flow on drop

On a successful drop, `TakeBox.accept()` calls `ItemManager.take(key)`. That method deducts FP, marks the item as owned, emits `item_level_changed`, and saves. It does not register effects with `EffectManager`, so paddle and ball see no change until the player equips the item later.

UI listeners react to the existing `friendship_point_balance_changed` and `item_level_changed` signals: `shop` refreshes the friendship label, every `ShopItem` re-evaluates its display case visibility, and the taken item's `ShopItem` hides itself in place so its slot becomes an empty gap (no "Taken" label, no reflow of siblings). `TakeBox` also emits `item_taken(definition)` for future polish hooks (sound, friend reaction).

---

## ItemManager changes

The current `ItemManager.purchase(item_key)` conflates owning an item with equipping its effects. That is fine for the dev item panel (which wants both in one click) but wrong for the shop: per 04-kit-and-locker, only equipped kit items fire effects, and equipping is a separate action the kit/locker UI owns.

SH-66 adds a new `take(item_key)` method that deducts FP, marks the item as owned, saves, and emits `item_level_changed`, but deliberately does **not** register effects with `EffectManager`. The shop calls this instead of `purchase()`.

The existing `purchase()` method stays unchanged so the dev panel and existing tests continue to work. The eventual kit/locker ticket will replace the dev panel's reliance on auto-equipping and `purchase()` can be deleted then.

---

## Drag preview

The drag preview is a small Control built fresh on every drag start by `ShopItem._build_drag_preview()`. It contains its own SubViewport rendering of the item's art scene, sized to roughly half the `ShopItem` size, with a modulate alpha of ~0.75 for translucency.

Why a fresh build each time: the preview is consumed by Godot's internal drag state and cannot be the same node as the item's own art viewport (which has to keep rendering in place). A throwaway preview Control avoids any node re-parenting games.

---

## Edge cases

Godot's built-in drag protocol handles cancellation silently: dropping outside any Control, on a Control that does not accept the payload, or on a target whose `can_accept` returns false at drop time all cancel the drag with no code. `_can_drop_data` is called repeatedly during hover, so a mid-drag state change (FP dips below cost, item becomes owned via another path) is caught at release and the drop is refused.

---

## Extensibility: multi-window drag (SH-51 forward compatibility)

SH-66 ships single-window drag and drop using Godot's built-in Control protocol. SH-51 introduces desktop mode where the shop, kit, locker, and compendium can live in separate OS windows, and items must be draggable between them. This section explains why the current design does not directly support that, and what has to change when SH-51 arrives.

### Why Godot's built-in drag does not cross windows

Godot's `_get_drag_data` / `_can_drop_data` / `_drop_data` protocol stores drag state on the source Control's `Viewport`. Drop targets are only considered if they share that viewport. In Godot 4, each OS window has its own root `Viewport`. When the cursor crosses an OS window boundary during a drag, the source viewport loses focus, the drag state is discarded, and the target viewport never sees the payload. This is not a bug: it is the intended behaviour of viewport-scoped input.

There is no flag to make it cross windows. The protocol itself is the wrong abstraction for the problem. SH-51 must introduce a different mechanism that operates in screen coordinates rather than viewport coordinates.

### What SH-51 will introduce

A `DragManager` autoload that tracks drag state in screen coordinates, renders the preview in a borderless `Window` that follows `DisplayServer.mouse_get_position()`, and maintains a registry of drop targets keyed by screen-space rects. Drop targets register themselves with `can_accept` and `accept` callables, and the manager picks the right target on mouse release based on screen position.

### What changes in `ShopItem` and `TakeBox`

Because the current design uses the forwarding pattern, the swap is mechanical: delete the Godot virtual methods, replace with `_gui_input` for drag start and `DragManager.register_drop_target` calls in `_ready`. The stable contract (`can_be_taken`, `build_drag_payload`, `build_drag_preview`, `can_accept`, `accept`) does not change. Nothing in the purchase flow, affordability logic, display case, signals, tests, or scene structure moves.

### Trade-offs accepted by SH-66

- We commit to the forwarding pattern from day one, adding one level of indirection the single-window implementation does not strictly need. The cost is a handful of delegation methods; the payoff is that SH-51 does not require a shop rewrite.
- We do not build a `DragManager` or abstract the drag preview mechanism now. The built-in Godot API is fine for one window; SH-51 introduces the abstraction when it is actually needed.

---

## Extensibility: inventory management (locker and kit)

The same stable contract handles the future locker↔kit drag flow. A `LockerItem` drag source implements `can_be_taken()` as "player owns it, not destroyed, not already in kit" and `build_drag_payload()` as "return the `ItemDefinition`". A `KitSlot` drop target implements `can_accept(definition)` as "slot eligible for this item type, slot empty or swappable" and `accept(definition)` as "call `ItemManager.equip_to_kit(key, slot_index)`". A `LockerSlot` drop target mirrors that for moving items back out of the kit.

Nothing in `ShopItem` or `TakeBox` changes when the kit/locker ticket lands. The shared `item_dragging.tscn` is reused as the drag preview for every source. Source context (which slot did this come from?) does not need to live on the payload because `ItemManager` is the source of truth for current state: a drop target calls `equip_to_kit(key, slot)` and `ItemManager` handles any displacement or swap internally based on where it currently knows the item is.

The only assumption this relies on is that `ItemManager` grows an `equip_to_kit` / `deactivate` pair (kit/locker ticket scope) and that those methods are state-aware enough to handle the full displacement logic without needing context from the drag source.

---

## Extensibility: direct-to-kit and direct-to-locker takes

Once the kit and locker UI exist alongside the shop, the player can drag a `ShopItem` straight onto a `KitSlot` or `LockerSlot` instead of routing through `TakeBox`. The `TakeBox` drop target stays as an explicit "deposit" affordance for players who prefer that gesture, or for layouts where the kit/locker UI is not currently visible, but it stops being the only path.

### Why this works without changing `ShopItem`

`ShopItem.build_drag_payload()` already returns a bare `ItemDefinition`. The payload carries no information about where the item came from, so any drop target that knows how to handle an `ItemDefinition` can accept it, regardless of source. The drag source has no opinion about which targets are valid; that lives entirely on the targets.

### What the kit and locker drop targets do

The acquisition step (taking the item out of the shop) and the placement step (putting it into a kit slot or locker slot) collapse into the drop target's `accept()` method. The target asks `ItemManager` whether the item is currently owned, and if not, calls `take(key)` first to acquire it, then proceeds with its normal placement logic:

```gdscript
# KitSlot.accept (illustrative)
func accept(definition: ItemDefinition) -> void:
    if ItemManager.get_level(definition.key) == 0:
        if not ItemManager.take(definition.key):
            return
    ItemManager.equip_to_kit(definition.key, slot_index)
```

`LockerSlot.accept()` is even simpler: if not owned, call `take`; if already owned (dragged from kit), call `deactivate`. There is no separate "from shop" code path; the slot just reads current state from `ItemManager` and does the right thing.

### Affordability gating

`ShopItem.can_be_taken()` already refuses to start a drag for unaffordable items, so kit and locker slots will not see unaffordable payloads in normal play. Defensively, their `can_accept(definition)` should still check affordability when the item is unowned. To avoid duplicating the affordability rule across every drop target, `ItemManager` grows a small predicate:

```gdscript
# ItemManager
func can_acquire(item_key: String) -> bool:
    return get_level(item_key) == 0 and _progression.friendship_point_balance >= calculate_cost(item_key)
```

`TakeBox.can_accept`, `KitSlot.can_accept`, and `LockerSlot.can_accept` all call this when the item is unowned. The `TakeBox` keeps its existing behaviour because `can_acquire` is exactly its current check, just named.

### Friend's pick slot interaction

The friend's pick slot is a property of the source (`ShopItem`), not the payload. Direct-to-kit and direct-to-locker takes do not change anything about how the pick slot is chosen, displayed, or refilled. The slot becomes empty after a successful take regardless of which target consumed it.

### What this does not introduce

- No new payload fields, no source context on the drag.
- No changes to the stable contract on `ShopItem` or `TakeBox`.
- No changes to `take`. It is the single acquisition primitive used by every target that needs to pull from the shop.
- No atomicity requirement between `take` and `equip_to_kit`. If the equip step fails after a successful take, the item is owned but unequipped, which is a valid resting state and matches what the player would see if they had used the box. The kit/locker UI surfaces this state as "in the locker"; that framing is the kit/locker ticket's concern, not `take`'s.

### Out of scope until the kit/locker ticket lands

`KitSlot`, `LockerSlot`, `equip_to_kit`, `deactivate`, and `can_acquire` are all kit/locker ticket scope. SH-66 only ships `TakeBox` and `take`. This section exists so the kit/locker ticket can wire direct takes in without renegotiating the contract.

---

## Testing strategy

Godot's end-to-end drag and drop is hard to exercise in GutTest because it requires a real `Viewport` in dragging state. Instead, test the stable contract directly: `can_be_taken`, `can_accept`, and `accept` are all Viewport-free and trivially unit-testable. Cursor preview, hover highlights, and drag feel rely on manual play-testing.

---

## Migration impact

This is a rewrite of the shop's interior, not a fresh feature. Files affected:

**Rewritten:**
- `res://scenes/shop.tscn` (Node2D root → Control root)
- `res://scenes/shop_item.tscn` (Node2D with Sprite2D → Control with SubViewport)
- `res://scripts/shop/shop.gd` (extends Control)
- `res://scripts/shop/shop_item.gd` (extends Control, new drag API)

**New:**
- `res://scenes/take_box.tscn`
- `res://scripts/shop/take_box.gd`
- `res://scenes/items/item_dragging.tscn` (shared drag preview, reused by future locker/kit sources)
- `res://scripts/items/item_dragging.gd`
- `res://tests/unit/test_take_box.gd`
- A "tink" sound effect asset for cased-item clicks (format and location per existing audio conventions)

**Updated:**
- `res://tests/unit/test_shop_item.gd` (new test coverage for drag API, remove tooltip-specific assertions if tooltip goes away)

**Unchanged:**
- `ItemManager`, `ItemDefinition`, `ProgressionManager`, `SaveManager`, all effect classes, all existing item `.tres` files
- Per-item art scenes under `res://scenes/items/`

**Deleted or deprecated:**
- The Parallax2D background and Camera2D from `shop.tscn`
- The `Area2D` hover detection on `ShopItem`
- The current hover tooltip wiring, if replaced by Godot's built-in tooltip

---

## Out of scope for SH-66

These live in the doc for context but are not in scope for this ticket:

- Rotation system (act-gated pools, paired gravity, friend's pick, discovery floor, safety net item). The prototype keeps the placeholder "first five unpurchased items" logic that already exists in `shop.gd`.
- Item destruction and second-chance variants.
- Cross-window drag for desktop experience.
- The shop winding-down phase (slot count drops, pick slot goes quiet).
- Friend reaction animations.
- Drag juice (tweens, scale pops, rubber-band snap-back).
- Display case art.
