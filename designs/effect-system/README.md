# Effect System

Every gameplay modifier in Volley flows through one framework: items, partners, the venue itself. Nothing goes around it.

The underlying principle is that effects are data, not code. No per-item script contains logic for what the item does. Instead, each effect is a resource that declares when it fires (trigger), whether it fires (conditions), and what it does (outcome). The evaluation loop is centralised in `EffectManager`; adding a new item means adding data.

This folder is the settled design authority. Implementation detail (class diagram, Godot file locations, SH-41/43 build status) lives in the prototype record at [`../01-prototype/tech/effect-system.md`](../01-prototype/tech/effect-system.md).

## Contents

| Doc | What it covers |
|---|---|
| [anatomy.md](anatomy.md) | The shape of an effect; sources and the registration path; level scaling |
| [evaluation.md](evaluation.md) | Event-to-outcome flow; resolution order; temporary modifiers and reset-on-miss |
| [reference.md](reference.md) | Stable vocabulary tables: trigger types, condition types, outcome types, modifier ops, expiry conditions, stat keys, named states |
| [runtime.md](runtime.md) | Oscillation, delayed effects, roll tables, item lifecycle as a model, signal payload contract |

## Cross-references (deferred; link, do not duplicate)

- Per-item effect definitions: [`../01-prototype/tech/05-item-effects.md`](../01-prototype/tech/05-item-effects.md)
- Item roles: [`../01-prototype/tech/06-roles.md`](../01-prototype/tech/06-roles.md)
- Tier and consolidation game design: [`../01-prototype/20a-ball-speed-tier-progression.md`](../01-prototype/20a-ball-speed-tier-progression.md)
