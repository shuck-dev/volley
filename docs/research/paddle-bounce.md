# Paddle Bounce: How the Genre Computes Return Angle

How paddle-and-ball games actually compute the post-bounce direction. Background reading for `01-prototype/tech/03-paddle-bounce.md`.

## Summary

The dominant pattern in paddle-and-ball games is to **replace** the incoming angle, not reflect it. The post-bounce direction is computed from where the ball touched the paddle (and in modern racket games, from player input at contact). Incoming angle is discarded. Pure angle-of-incidence reflection is described in the source material as "the most simplistic Pong" and was the design Atari moved away from in 1972 because it played as "too boring."

## Classic Pong (1972, Atari)

Allan Alcorn divided the paddle into eight segments. Centre segments returned the ball at 90° to the paddle; outer segments at smaller angles. There was no continuous function and no preservation of incoming angle: the segment alone picked the output direction. Sources call this "completely arbitrary" but functional, designed to add strategic depth without floating-point math the hardware did not have [^pong-wiki] [^cornell-pong] [^bespoke-pong].

## Breakout / Arkanoid family

Every reference describes the same pattern: compute hit offset (`ball.x − paddle.x`), normalise to roughly `[-1, +1]`, use that as the new x-component, set y-component to a fixed positive value, normalise, multiply by speed. Incoming angle is discarded. Some variants additionally mix in paddle velocity for "english" [^breakernoid] [^smiling-cat] [^gamedev-breakout].

## Modern paddle / racket games

Three patterns surveyed, all of which discard pure angle-of-incidence reflection:

- **Wii Sports / Switch Sports tennis**: direction is a function of swing timing, not paddle geometry. Early swing on forehand goes cross-court, late swing goes down-the-line. Wrist angle reads spin [^wii-tennis-sw] [^wii-tennis-wiki].
- **Lethal League / Lethal League Blaze**: "neutral swing" releases the ball at one of three player-selected angles (Up / Neutral / Down) at the moment the swing animation ends. Incoming angle fully replaced [^lethal-league].
- **Windjammers**: holding a direction at contact angles the disc diagonally; per-character "attack angles" the disc differently [^script-routine].

Every modern racket-feel game gives the player intent at the contact moment, and that intent picks the new direction.

## Canonical tutorial pattern

All most-referenced 2D-physics tutorials replace the incoming direction with a hard-coded y-sign:

- **MDN / Phaser Breakout**: `ball.body.velocity.x = -5 * (paddle.x - ball.x)` [^mdn-phaser].
- **CS50 Breakout (Lua/LÖVE)**: `ball.dx = ±50 + ±8 * |paddle.center - ball.x|`. Additive with a non-zero floor, gated by paddle movement direction [^cs50-breakout].
- **StudyPlan SDL2 Breakout**: offset normalised to `[-1, +1]` becomes x, y forced to a positive constant [^studyplan-sdl2].
- **MonoGame Breakernoid**: same shape, with clamping to avoid near-vertical bounces [^breakernoid].

Common refinements in the tutorials: clamp away from horizontal-near-vertical, mix paddle velocity for english, renormalise to constant ball speed after the math.

## On the semantic question

No Steve Swink or Game Maker's Toolkit piece lands cleanly on "preserve incoming angle vs replace it" for racket games, but the surrounding material is consistent:

- Pure angle-of-incidence reflection is treated as a baseline to improve on, not a target feel [^gamedev-pong].
- The shipped 1972 Pong intentionally departed from pure reflection because Alcorn felt the game was "too boring" without the 8-segment table [^pong-wiki].
- Tutorials explicitly justify offset-overwrite as "where the ball hits the paddle has a strong effect on direction... this is what gives players control" [^breakernoid] [^studyplan-sdl2].
- Real tennis physics: perpendicular-to-racket velocity is roughly preserved, but the parallel-to-racket component reverses, and string friction plus spin make the bounce deviate significantly from incidence. Even the realistic reference does not behave like a mirror [^tennis-physics].

The genre convention, taught in every tutorial and shipped in every reference game found, is that contact offset or player input at contact picks the post-bounce direction and incoming angle is largely or wholly discarded.

## Sources

[^pong-wiki]: [Pong, Wikipedia](https://en.wikipedia.org/wiki/Pong). Retrieved 2026-05-13.
[^cornell-pong]: [Atari's Pong Reimagined, Cornell ECE4760](https://ece4760.github.io/Projects/Fall2023/dms489_kw462/FinalProjectAtarisPongReimagined.html). Retrieved 2026-05-13.
[^bespoke-pong]: [Pong, Bespoke Arcades](https://bespoke-arcades.co.uk/blogs/blog/pong-1972). Retrieved 2026-05-13.
[^breakernoid]: [Building Breakernoid in MonoGame, InformIT](https://www.informit.com/articles/article.aspx?p=2180417&seqNum=2). Retrieved 2026-05-13.
[^smiling-cat]: [Physics for a Block Breaker Game, Smiling Cat](https://www.smilingcatentertainment.com/physics-for-a-block-breaker-game/). Retrieved 2026-05-13.
[^gamedev-breakout]: [Breakout-bounce thread, GameDev.net](https://www.gamedev.net/forums/topic/108709-help-plz-breakoutarkanoid-clone-bouncing-ball-giving-it-angles-etc/). Retrieved 2026-05-13.
[^wii-tennis-sw]: [Wii Sports Tennis, StrategyWiki](https://strategywiki.org/wiki/Wii_Sports/Tennis). Retrieved 2026-05-13.
[^wii-tennis-wiki]: [Tennis, Wii Sports Wiki](https://wiisports.fandom.com/wiki/Tennis_(sport)). Retrieved 2026-05-13.
[^lethal-league]: [Gameplay/Mechanics, Lethal League Wiki](https://lethal-league.fandom.com/wiki/Gameplay/Mechanics). Retrieved 2026-05-13.
[^script-routine]: [Sports Game Triple Play: Pong → Windjammers → Lethal League, Script Routine](https://scriptroutine.com/2020/12/05/sports-game-triple-play-evolving-pongs-design-into-windjammers-and-lethal-league/). Retrieved 2026-05-13.
[^mdn-phaser]: [Randomizing gameplay, MDN Phaser Breakout tutorial](https://developer.mozilla.org/en-US/docs/Games/Tutorials/2D_breakout_game_Phaser/Randomizing_gameplay). Retrieved 2026-05-13.
[^cs50-breakout]: [Breakout notes, CS50G](https://cs50.harvard.edu/games/notes/2/). Retrieved 2026-05-13.
[^studyplan-sdl2]: [Breakout Paddle Physics, StudyPlan SDL2](https://www.studyplan.dev/sdl2/sdl2-breakout-paddle-physics). Retrieved 2026-05-13.
[^gamedev-pong]: [Best PONG bounce method, GameDev.net](https://www.gamedev.net/forums/topic/169021-best-pong-bounce-method/). Retrieved 2026-05-13.
[^tennis-physics]: [Physics of Tennis, Tennis Without Talent](https://www.tenniswithouttalent.com/Physics.html). Retrieved 2026-05-13.
