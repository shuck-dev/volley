# Volley!

Volley! is a desktop idle game shaped like a tennis rally. The ball goes back and forth between the protagonist and a coach who arrives one round at a time. A counter on the wall climbs. A friend leans on the counter of a small wooden stall on the far side of the play, watching the protagonist play, glad to be there. In another corner, the friend's younger sister works at a bench, fixing what the protagonist brings her.

Underneath the loop sits a story the player meets gradually. Cracks accumulate. The second layer earns its weight by the time the player can read it. What the rally already gave stays earned. The game holds for both readers: someone who only wants the rally running while they work, and someone who notices the names, the digits in the count, the weight a pong-shaped game has not asked for.

## How these docs work

One page per thing. If you want to know how the ball works, read [Ball](ball/INDEX.md). If you want to know who Zach is, read [Shopkeeper](characters/shopkeeper.md).

Each page runs from the outside in: what the thing is in the fiction, then how it is designed to play, then how it is built. Read as far down as you need and stop.

**These docs describe the game that exists.** Construction is what is built, so Construction is what is written down. Acts past it are not documented until they are real, and a feature nobody has built does not get a page. When something is cut from the game it is cut from here too.

## Where to start

An **engineer** new to the codebase: [North Star](north-star.md), then the entity page for whatever you are touching.

An **artist** picking up a brief: [Artist Brief](art/brief.md), then the [Art Bible](art/bible.md).

Someone working on the **fiction**: [Story](story/INDEX.md) and the [Characters](characters/INDEX.md).

An **open-source visitor**: [The Case for Open Development](research/the-case-for-open-development.md) is the project's published essay on why the work is in the open. [CONTRIBUTING.md](https://github.com/shuck-dev/volley/blob/main/CONTRIBUTING.md) is the practical entry point.

## The game

| Page | What it covers |
|---|---|
| [Ball](ball/INDEX.md) | The ball, its lifecycle, the roster, speed tiers, physics. |
| [Soul](soul/INDEX.md) | The currency. Gathering it, consolidating it, spending it. |
| [Item](item/INDEX.md) | What an item is, how items are authored, how they move. |
| [Shop](shop/INDEX.md) | Zach's stall. Buying balls, restocking. |
| [Kit](kit/INDEX.md) | The staging area for balls not in play. |
| [Court](court/INDEX.md) | The play surface, its bounds, the miss. |
| [Venue](venue/INDEX.md) | The place it all sits in. |
| [Partner](partner/INDEX.md) | The rally partner and the AI behind them. |
| [Save](save/INDEX.md) | The save format and how it versions. |
| [Idle](idle/INDEX.md) | Play that continues without the player. |

## The people

| Page | Who |
|---|---|
| [Characters](characters/INDEX.md) | The cast, at a glance. |
| [Protagonist](characters/protagonist.md) | The person at the centre, and the racquet in their hand. |
| [Shopkeeper](characters/shopkeeper.md) | Zach. |
| [Tinkerer](characters/tinkerer.md) | Stephanie. |
| [Martha](characters/martha.md) | The first partner. |
| [Fern](characters/fern.md) | The champion. |
| [Partners](characters/partners.md) | The lineage rule and the wider cast. |

## Craft

| Page | What it covers |
|---|---|
| [Art](art/INDEX.md) | The visual design, the pipeline, the references. |
| [Audio](audio/INDEX.md) | The score, the sound design, the engine seam. |
| [Story](story/INDEX.md) | Construction, as it stands. |

## Working

| Page | What it covers |
|---|---|
| [Process](process/INDEX.md) | How the team writes, files, and runs the work. |
| [CI](ci/INDEX.md) | Assets, the LFS proxy, exports. |
| [Spikes](spikes/INDEX.md) | Decision records. Why a thing is the way it is. |
| [Research](research/INDEX.md) | The public essay, plans, references, studies. |

## Top-level

| Doc | Purpose |
|---|---|
| [North Star](north-star.md) | What the game is, who it is for, what it asks of the player. |
| [Roadmap](roadmap.md) | The five phases at a glance. |
