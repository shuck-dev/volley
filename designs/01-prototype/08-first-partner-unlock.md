# First Partner Unlock

## Goal
Let the player spend FP to recruit Martha, their first partner, adding a second paddle on the right side of the net. When Martha is active, the right wall becomes a miss zone instead of a bounce surface. This is the first moment the game's cast exists in the world.

**Points:** Spike
**Dependencies:** Progression System (FP economy, save/load), Progression Manager (unlock tiers), Effect System (partner as effect source)

## Current state

The right side of the arena is a `StaticBody2D` wall (`back_wall.gd`) that bounces the ball back. The player paddle is a `CharacterBody2D` on the left with input handling, item-driven speed/size, and hit tracking. Autoplay AI exists in `AutoplayController` and drives the player paddle during idle mode using a reaction-delay buffer and speed-capped tracking.

The Progression Manager (SH-32) already handles the shop unlock: it listens to `ItemManager.friendship_point_balance_changed`, checks a threshold from config, flips a flag in `ProgressionData`, persists, and emits a signal. The partner unlock is another tier in this same system.

There is no concept of a partner, no second paddle, and no partner unlock tier.

## Martha

Martha was the cashier at the local newsagent. Somewhere in Britain, a small shop, the kind you pop into most days. She always had a smile waiting. They'd chat about nothing: the weather, something in the paper, a thing she saw on telly. Maybe they hung out once or twice outside the shop, but it never became a regular thing. She was a fixture, not a friend exactly, but someone who made the day a little warmer.

The main character brings Martha into the game first because she's the lowest-risk memory. No history to untangle, no falling out, no guilt. Just someone who was reliably kind to them. Recruiting Martha is the paddle reaching for warmth without having to face anything painful.

Every partner has an ordinary human name. The names directly reference people who affected the main character in their reality. Martha feels like someone you could know, because she is someone the paddle once knew.

Partners express personality through three channels: art (visual identity, expressions), monologue barks (short, unprompted lines that surface during play), and effects (mechanical bonuses that reflect who they are). The AI itself is simple; pong does not have room for meaningful play style differentiation. All partners use the same AI. The character comes through in what you see, what they say, and what they give you.

**What makes Martha interesting narratively:** She barely knew the main character, but she treated them like they mattered. In pre-break play, her barks read as generic encouragement. On replay after the break, you realise she's saying the same kind of things she always said: small, warm, nothing special. But the main character remembered them exactly. She might reference the shop, or something you'd only say to someone you see every day but don't really know. Things that don't quite fit a pong game.

She is the baseline. Martha is uncomplicated. The partners that come after won't be.

Martha's effects reinforce the feeling that she is a good partner to have around: rallies feel slightly more rewarding with her, and the game pushes a little harder because two people can handle more than one.

## Scope

### In scope
1. Partner data model and persistence
2. Partner unlock tier in the Progression Manager (same system as shop unlock)
3. Partner paddle (added in front of the right wall; right wall hit becomes a miss)
4. Partner AI (dedicated processor, separate from autoplay)
5. Partner effects (registered as an effect source via the effect system)
6. Monologue barks (short, unprompted lines during play)
7. Partner volley contribution (partner hits count toward the streak)
8. Recruit HUD (prompt to recruit when threshold is reached)
9. Partner intro sound effect
10. Save/load for partner unlock state

### Out of scope
- Multiple partners or partner selection
- Partner visual identity or character art (art work)
- Partner HUD presence beyond recruit prompt (art/UI work)
- Shop-based unlock flow (the shop is a separate system; prototype uses a direct FP spend)

## Features

### 1. Partner data model

A partner is a named character who plays on the right side of the net. For prototype, only Martha exists. The data model should support multiple partners but the unlock flow only handles the first.

Partner state tracked in `ProgressionData`:
- `unlocked_partners: Array[String]`: list of partner keys the player has recruited. Empty at start.
- `active_partner: String`: the currently active partner key. Empty string means no partner (wall mode).
- `partner_volley_totals: Dictionary[String, int]`: cumulative volleys played while each partner is active. Used for compendium mastery (see `07-item-compendium.md`). The compendium entry for a partner unlocks when their volley count reaches a threshold. Same threshold for all partners, tuning target for Make Fun pass.

The `Partner` resource (as defined in the effect system design) provides `effects: Effect[]`. The partner is registered as an effect source with `EffectManager` when active, exactly like items are. This means partner effects flow through the same stat resolution, trigger evaluation, and outcome routing as item effects. Partners do not have a relationship level; progression moments are driven by story beats.

### 2. Partner unlock tier

The partner unlock is a tier in the Progression Manager, the same system used for the shop unlock (see `03-progression-manager.md`). The Progression Manager listens to `ItemManager.friendship_point_balance_changed`, checks whether the partner unlock threshold has been reached, flips `martha_unlocked` in `ProgressionData`, persists, and emits `partner_unlocked_changed`.

**Threshold:** Defined in `ProgressionConfig`, not hardcoded. Higher than the shop unlock threshold (shop is 50 FP). Starting point is a tuning target for the Make Fun pass.

**Unlock cost:** Uses the same cost system as items. The base cost is defined on the partner resource, keeping the economy consistent.

**Permanent:** Like the shop unlock, the partner unlock does not re-lock if FP drops below the threshold after purchase.

### 3. Partner paddle

The partner paddle sits in front of the right wall. The right wall remains in the scene; when Martha is active, the ball hitting the right wall counts as a miss (Martha failed to return it) rather than bouncing back.

The partner paddle extends a shared paddle interface rather than reusing the player's `Paddle` class with input disabled. The player paddle has player input; the partner paddle has no input source at all. Both share the same physics behaviour (collision, bounce) and the same `paddle_hit` / `drive()` contract, but they are distinct types.

**Partner paddle specifics:**
- No player input. Movement comes entirely from the partner AI processor.
- Same collision and bounce physics as the player paddle.
- Does not benefit from player items (paddle speed, paddle size). Has its own base stats matching the player's unupgraded defaults.
- On load, if `active_partner` is set, the partner paddle is present from the start.

### 4. Partner AI

The partner AI is a dedicated processor, separate from `AutoplayController`. The autoplay controller handles the player's idle toggle and interacts with player input state. The partner AI is always active and has no relationship to the player's autoplay toggle.

The partner AI drives the partner paddle via `drive()` each physics frame. All partners use the same AI; pong is too simple for meaningful play style differentiation between partners. The AI tracks the ball, returns it, and misses believably at high speeds.

**Configuration:** The partner AI has its own config resource. Starting values are a tuning target for the Make Fun pass.

### 5. Partner effects

Martha is an effect source, registered with `EffectManager` when active and unregistered when not. Effects are defined on the `Partner` resource using the same `Effect` structure as items: trigger, conditions, outcomes.

Martha has two effects: one FP bonus and one causality effect.

**Effect 1: FP bonus (always)**

A percentage increase to `friendship_points_per_hit` (e.g. +25% percentage). Having Martha around makes every rally a bit more rewarding. This scales with other FP modifiers: as the player acquires items that boost FP per hit, Martha's bonus grows with them. Tuning target for Make Fun pass.

```
Effect 1
  trigger: always
  outcome: percentage(friendship_points_per_hit, +25%)
```

**Effect 2: Half streak (on miss)**

When the player misses, the streak drops to half (rounded down) instead of resetting to zero. Ball speed also halves proportionally instead of fully resetting. Martha doesn't prevent the miss. She makes it so you don't lose everything.

No item touches streak continuity. This is unique to Martha and changes how the game feels fundamentally. Before Martha, every miss is a full reset. After Martha, misses are setbacks, not catastrophes. The better you're doing, the more Martha matters: half of 10 is 5, half of 100 is 50.

This needs a new outcome type: `halve_streak`. On miss, instead of resetting the volley count to zero, set it to `floor(current_streak / 2)`. Ball speed is set to the speed that corresponds to that streak position, calculated through the effect system's normal stat resolution. This means items that modify ball speed (Cadence's oscillation, Court Lines' max range increase, Training Ball's min speed increase) are respected: the halved speed lands at the right point within the current modifier stack, not at a raw unmodified value. Temporary modifiers (`stat_until_miss`) still clear as normal on miss; `halve_streak` runs after that cleanup.

```
Effect 2
  trigger: on_miss
  outcome: halve_streak
```

The partner's effects are active whenever the partner is active. They are not tied to the partner's paddle hitting the ball; they are passive bonuses from having a partner in the game.

### 6. Monologue barks

Martha surfaces short, unprompted lines during play. See `08-bark-system.md` for the full system design: pool-based selection, recency exclusion, context-aware pools, cooldowns, and chance-to-fire.

Martha speaks rarely and never on every trigger. She comments on misses (with a quieter tone when things are going badly), long rallies, and returning after being away. She does not comment on milestones, speed changes, or individual hits. Her silence on those triggers is deliberate: she's not a coach, she's a friend.

```
Pool 1: Player miss
  trigger: on_miss
  context: { miss_side: "player" }
  chance: 0.35
  cooldown: 45s
  priority: 1
  lines:
    - "Don't worry about it"
    - "Happens to the best of us"
    - "Nearly had it"
    - "That one was quick"
    - "Ah, close"
    - "We go again"
    - "Shake it off"
    - "You'll get the next one"
    - "Gone before you blinked"
    - "Nothing wrong with that"
    - "That's the ball's fault, not yours"
    - "Right then, next one"
    - "Unlucky"
    - "Chin up"
    - "That one had ideas of its own"

Pool 2: Martha miss
  trigger: on_miss
  context: { miss_side: "partner" }
  chance: 0.35
  cooldown: 45s
  priority: 1
  lines:
    - "Sorry, that was me"
    - "My fault"
    - "I should've had that"
    - "Ugh, sorry"
    - "That one got past me"
    - "I was miles away"
    - "Won't happen again"
    - "Bit slow there, wasn't I?"
    - "I'll get the next one"
    - "Didn't read it right"
    - "That was rubbish, sorry"
    - "Caught me out"
    - "I'll do better"
    - "Wasn't ready for that one"
    - "My bad"

Pool 3: Long rally
  trigger: on_streak_milestone
  context: { streak_above_percentage_of_pb: 0.5 }
  chance: 0.3
  cooldown: 60s
  priority: 1
  lines:
    - "We're proper going today, aren't we?"
    - "This is a good one"
    - "Look at us"
    - "Keep it going"
    - "How long can we keep this up?"
    - "Don't think about it, just play"
    - "Oh, that was a good one!"
    - "We're in the zone"
    - "I'm not even blinking"
    - "This is the one, I can feel it"
    - "You're making it look easy"
    - "Steady now"
    - "Don't jinx it"
    - "I'm holding my breath over here"
    - "Reckon this could be a record?"
    - "I've gone all tingly"
    - "Alright, I'm impressed"
    - "You're on one today"
    - "Magic, this"
    - "Every single one, just like that"

Pool 4: Return after idle
  trigger: on_return_after_idle
  context: {}
  chance: 0.8
  cooldown: 0s
  priority: 1
  lines:
    - "There you are"
    - "Kettle's on"
    - "Was wondering when you'd be back"
    - "Alright?"
    - "Good to see you"
    - "Missed you"
    - "Ready when you are"
    - "How's things?"
    - "Look who it is"
    - "Been keeping your spot warm"
    - "Thought you'd gone for good"
    - "Welcome back"
    - "There she is"
    - "Usual, is it?"
    - "Right on time"
    - "I saved you the good one"
    - "Wasn't the same without you"
    - "Oh hello"
    - "You look well"
    - "Busy day?"

Pool 5: Idle chatter
  trigger: on_timer
  context: {}
  chance: 0.3
  cooldown: 120s
  priority: 1
  lines:
    - "Nice day for it"
    - "Quiet in here today"
    - "Did you see the rain earlier?"
    - "Had the weirdest dream last night"
    - "Someone left their umbrella in yesterday"
    - "I've been thinking about getting a cat"
    - "Do you ever just watch the clouds?"
    - "Apparently it's meant to be warm this weekend"
    - "Found 50p this morning. Good omen, I reckon"
    - "Bloke from number twelve moved out. Just like that"
    - "You know what I fancy? Chips"
    - "I keep meaning to sort the back shelf"
    - "There was a fox in the garden last night. Just sat there"
    - "I changed the display this morning. Bet you didn't notice"
    - "I've started doing the crossword. Rubbish at it"
    - "That clock's been wrong for months. Nobody's said anything"
    - "Do you think birds get bored?"
    - "Got a song stuck in my head. Can't place it"
    - "Someone came in asking for stamps earlier. Stamps!"
    - "The light goes funny in here around four o'clock"
    - "I keep a list of things I want to do. Never do any of them"
    - "There's a cobweb up there. Proper engineering, that"
    - "I reorganised the crisps. Don't know why"
    - "My nan always said no news is good news"
    - "Have you tried that new place down the road? Neither have I"
    - "I like this time of day. Everything slows down"
    - "I counted all the tins yesterday. Hundred and twelve"
    - "Sometimes I just stand here and listen. It's nice"
    - "Smells like rain"
    - "I wonder what's on telly tonight"
```

100 lines across 5 pools (15 + 15 + 20 + 20 + 30). Player miss and Martha miss are separate. Idle chatter is the largest pool: Martha filling comfortable silences with small talk about nothing, the way she would at the newsagent.

#### Post-break barks

Not implemented for prototype. Included here to illustrate how barks shift after the break without changing Martha's voice. She's still warm, still chatty, still Martha. But some lines are too specific. They reference the shop, the routine, the fact that she was someone real. Pre-break these would feel like flavour. Post-break the player knows what they mean.

The pools and triggers stay the same. The lines swap out.

```
Pool 1: Player miss (post-break)
  trigger: on_miss
  context: { miss_side: "player" }
  chance: 0.35
  cooldown: 45s
  priority: 1
  lines:
    - "You always did drop things"
    - "I've seen you fumble worse than that"
    - "Remember when you knocked over the display? This is nothing"
    - "You used to do that with your change too"
    - "Some things don't stick. That's alright"
    - "You never could hold onto the good ones"
    - "You always came back for another go"
    - "I'd have picked that up for you if I could"
    - "Butterfingers"
    - "Not the end of the world"
    - "You'll sort it"
    - "That's nothing. You should've seen Tuesday"
    - "Worse things happen"
    - "You never let that stop you before"
    - "Goes like that sometimes"

Pool 2: Martha miss (post-break)
  trigger: on_miss
  context: { miss_side: "partner" }
  chance: 0.35
  cooldown: 45s
  priority: 1
  lines:
    - "I never was any good at this bit"
    - "Should've been paying attention"
    - "My head was somewhere else. Sorry"
    - "I was thinking about something. Doesn't matter"
    - "That reminded me of something"
    - "Sorry. Lost my train of thought"
    - "I used to be better at catching things"
    - "Dropped it. Story of my life"
    - "My hands aren't what they were"
    - "I got distracted. Won't say by what"
    - "That was careless of me"
    - "I keep doing that"
    - "Sorry. I was miles away. Actual miles"
    - "Wasn't concentrating. Bad habit"
    - "Let that one go. Didn't mean to"

Pool 3: Long rally (post-break)
  trigger: on_streak_milestone
  context: { streak_above_percentage_of_pb: 0.5 }
  chance: 0.3
  cooldown: 60s
  priority: 1
  lines:
    - "Just like old times"
    - "This reminds me of something"
    - "We used to be good at this. We still are"
    - "Don't stop now. Please don't stop"
    - "I forgot how this felt"
    - "You always had this in you"
    - "I knew you could do this. I always knew"
    - "Keep going. I'm right here"
    - "This is the best it's been in a long time"
    - "I don't want this one to end"
    - "You're doing so well"
    - "I wish you could see yourself right now"
    - "Stay with me"
    - "This is why I'm here"
    - "Remember this feeling"
    - "We've got something going, haven't we?"
    - "I'm not going anywhere"
    - "This feels different to before"
    - "Is this what it was always supposed to feel like?"
    - "You're not the same as before. That's good"

Pool 4: Return after idle (post-break)
  trigger: on_return_after_idle
  context: {}
  chance: 0.8
  cooldown: 0s
  priority: 1
  lines:
    - "You came back"
    - "I wasn't sure you'd come back"
    - "It's been quiet without you"
    - "I kept the light on for you"
    - "Same time as always"
    - "I'd have waited longer, you know"
    - "You look different. Good different"
    - "Feels like ages since I've seen you"
    - "I was just thinking about you"
    - "The bell above the door still works then"
    - "Wasn't sure you remembered the way here"
    - "I saved your spot by the counter"
    - "Thought about closing up. Glad I didn't"
    - "There you are. There you are"
    - "Some things don't change, do they?"
    - "I'd know that walk anywhere"
    - "It's really you"
    - "I hoped you'd come by today"
    - "The door's always open for you"
    - "You don't have to explain where you've been"

Pool 5: Idle chatter (post-break)
  trigger: on_timer
  context: {}
  chance: 0.3
  cooldown: 120s
  priority: 1
  lines:
    - "The shop's still here. In case you were wondering"
    - "I restocked the top shelf. No one buys from it"
    - "Your paper's still on the counter"
    - "Do you remember the summer it rained for three weeks?"
    - "I still think about that Tuesday"
    - "The bell above the door needs fixing. Always has"
    - "Someone asked about you the other day"
    - "I found one of your old receipts behind the till"
    - "The streetlight outside flickers at night. Always did"
    - "I still put the kettle on at half three"
    - "Everything looks the same but it isn't really"
    - "There's a crack in the counter I never fixed"
    - "I kept your change from last time. Doesn't matter now"
    - "The view from here hasn't changed"
    - "I wonder if you'd recognise the place"
    - "Some mornings I open up and forget why"
    - "That cat came back again. The ginger one"
    - "I still do the crossword. Still rubbish"
    - "Funny how some days feel longer than others"
    - "I used to close at six. Now I don't know when to stop"
    - "Do you remember what you bought the first time?"
    - "The radio broke. I just hum now"
    - "I water the plant by the door. Don't know what it is"
    - "Someone left a note in a magazine once. Never found out who"
    - "It's quieter than it used to be"
    - "I alphabetised the crisps again. Old habits"
    - "The rain sounds different in here than outside"
    - "I think about closing sometimes. Just think about it"
    - "You were always the best part of the morning"
    - "It's nice, this. Just being here"
```

100 post-break lines across the same 5 pools (15 + 15 + 20 + 20 + 30). Martha's voice is the same. The weight is different. The shop references, the specificity of memory, the quiet acknowledgement that things have changed: these are the signal layer. Pre-break they'd feel like quirky flavour. Post-break the player knows Martha was real and these hit differently.

### 7. Partner volley contribution

Martha's paddle emits `paddle_hit` when she hits the ball. `game.gd` connects to both paddles' `paddle_hit` signals and increments the volley count for either. FP is earned on both player and partner hits using the same accumulation logic. The autoplay FP rate reduction is a game state: when the player is in autoplay, all FP earning is affected regardless of which paddle hit the ball.

**Miss behaviour:**

When Martha is active, the right wall becomes a miss zone. The ball hitting the right wall means Martha failed to return it. Both left misses (player) and right misses (Martha) reset the streak.

Other consequences of a partner miss are worth considering: does the partner's miss carry a different weight than the player's? Should Martha's miss feel more forgiving (smaller penalty, a consolation effect) or the same? For prototype, both sides reset the streak identically. This is a design question for refinement.

**Partner paddle visual:**

Martha's paddle is visually distinct from the player's paddle. For prototype, a colour change is enough. The player paddle is always on the left; Martha is always on the right.

### 8. Recruit HUD

When the unlock threshold is reached and Martha is not yet unlocked, a recruit prompt appears: her name, the FP cost, and a recruit button. The prompt is dismissible but reappears next session if not acted on. It does not interrupt gameplay.

### 9. Partner intro sound

A single sound effect plays when Martha is recruited. This marks the moment. No animation, no transition sequence. The sound and the paddle appearing are enough for prototype.

### 10. Save/load

`ProgressionData` gains `unlocked_partners` and `active_partner` fields. Both are included in `to_dict()` / `from_dict()`. On load, if a partner is active, the game initializes with the partner paddle and the right wall in miss-zone mode.

## Architecture

### Partner data in `ProgressionData`

```
# progression_data.gd additions
var unlocked_partners: Array[String] = []
var active_partner: String = ""
var partner_volley_totals: Dictionary[String, int] = {}
```

Include in `to_dict()` / `from_dict()`. The `active_partner` field drives scene setup on load.

### Progression Manager tier

Add `partner_unlock_threshold` to `ProgressionConfig`. Add `martha_unlocked` to `ProgressionData`. The Progression Manager checks this threshold the same way it checks `shop_unlock_threshold`: on `friendship_point_balance_changed`, check if threshold is met and flag is false, flip, persist, emit `partner_unlocked_changed(is_unlocked: bool)`.

### Paddle interface

Extract a shared interface from the current `Paddle` class. Both the player paddle and partner paddle implement it. The interface provides `drive()`, `on_ball_hit()`, `reset_streak()`, `get_speed()`, and the `paddle_hit` signal. The player paddle adds input handling in `_physics_process`. The partner paddle has no input handling; it is driven entirely by the partner AI processor.

### Partner AI processor

A dedicated node that drives the partner paddle. Separate from `AutoplayController`. All partners share the same AI; no per-partner tuning. It calls `drive()` on the partner paddle each physics frame.

### Effect registration

When Martha becomes active, `EffectManager.register_source(martha_resource)` is called. When deactivated, `EffectManager.unregister_source(martha_resource)` cleans up. Same lifecycle as item equip/unequip.

### Right wall miss zone

The right wall remains in the scene. When Martha is active, the ball hitting the right wall triggers a miss instead of bouncing. This can be handled by changing the right wall's behaviour (signal or callback) based on whether a partner is active, or by swapping the wall's physics material/layer so the ball passes through to a miss-detection area behind it.

### Scene setup in `game.gd`

`game.gd` checks `active_partner` on `_ready()`:
- If empty: right wall bounces, no partner paddle.
- If set: partner paddle instantiated and positioned, partner AI started, `paddle_hit` connected, partner registered as effect source, right wall set to miss-zone mode.

The partner unlock flow (triggered from recruit HUD) calls a method on `game.gd` that performs the setup at runtime without reloading the scene.

## Test plan

- Partner unlock deducts FP and persists across save/load
- Partner unlock is rejected when FP is insufficient
- Partner paddle returns the ball and increments the volley streak
- FP accumulates on partner hits
- Ball hitting the right wall is a miss when a partner is active
- Ball hitting the right wall bounces when no partner is active
- Partner effects apply to stat queries while active and are removed when not
- Recruit prompt appears when FP threshold is reached
- Partner intro sound plays on recruit

## Open questions

- When the partner misses, should there be a consequence beyond streak reset? Could Martha's miss feel different from the player's miss? Both sides reset the streak for prototype, but this is worth exploring.
