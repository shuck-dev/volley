# Item UI — Diegetic Drag and Drop

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

## Open questions for spike

- Control nodes (UI drag/drop) vs Node2D (world-space diegetic)?
- How does the shop fit — are items dragged from a shop area into the kit?
- What happens visually when a slot is full (swap vs reject)?
- How does item level and degradation state show on the card?
- Can items be dragged during a rally, or only between rounds?

---

## Notes

- The `Item` resource is pure data — no visual nodes. The draggable scene owns visuals and reads from the resource.
- ItemManager handles all registration/equip logic triggered by drop events.
