# Item UI: Diegetic Drag and Drop

Design notes for how items are presented and manipulated in the UI.

---

## Core concept

Items are diegetic objects. They exist as physical cards or objects in the world that the player drags between slots. No abstract menus. The player sees their kit laid out in front of them and physically moves items between kit slots and the locker.

---

## Interaction model

- Items are draggable objects (Control or Node2D scene)
- Each item scene holds a reference to its `Item` resource and reads it for display data (sprite, name, description state)
- Slots are drop targets: kit slots and locker slots
- Dragging an item from one slot to another triggers equip/unequip logic in ItemManager

---

## In-panel drag-and-drop

The clearance, kit, and locker all use Control node drag-and-drop within a single UI panel. This is standard Godot UI: draggable Control nodes dropped onto slot targets. No spike needed.

- Clearance: drag items from the friend's things into the box to take them
- Kit/locker: drag items between kit slots and locker slots to equip/unequip

---

## Desktop experience: cross-window drag-and-drop

The game runs as multiple OS windows on desktop. The open question is how to drag items between separate windows (e.g. dragging an item from a locker window into a kit window).

A fullscreen mode is also planned to support portable devices (e.g. Steam Deck), where multiple OS windows are not available. The cross-window drag solution must have a fullscreen equivalent.

This is the scope of SH-51.

---

## Open questions

- Cross-window drag: OS-level drag, shared viewport, or something else?
- How does cross-window drag translate to fullscreen mode on portables?
- What happens visually when a slot is full (swap vs reject)?
- How does item level and degradation state show on the card?
- Can items be dragged during a rally, or only between rounds?

---

## Drag-and-drop feel

Diegetic drag-and-drop needs to feel physical. A juice/tweening library from AssetLib (e.g. Godot Juice) would help with:

- Item pickup: slight scale pop and shadow shift when grabbed
- Hover over valid slot: slot glow or pulse
- Drop: satisfying snap with a small bounce settle
- Reject (invalid drop): item rubber-bands back to origin

These are not cosmetic. Without tactile feedback, dragging a Control node feels like moving a rectangle. With it, it feels like picking up an object. Evaluate during the Make Fun pass whether the built-in Tween is sufficient or a library is worth pulling in.

---

## Notes

- The `Item` resource is pure data — no visual nodes. The draggable scene owns visuals and reads from the resource.
- ItemManager handles all registration/equip logic triggered by drop events.
