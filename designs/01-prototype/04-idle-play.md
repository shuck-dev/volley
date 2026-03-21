# Idle Play

## Goal
Make the game play itself so it feels alive on your desktop, and reward the player for time away.

## Features

### 1. Auto-play
- Paddles rally on their own without player input
- AI is imperfect, misses sometimes, streaks end naturally
- Player can take over at any time by moving their mouse/paddle
- FP earned at a reduced rate compared to active play

### 2. Background play
- Game continues running when minimized or unfocused
- Keeps earning FP passively
- Visual activity resumes when the window is focused again

### 3. Offline rewards
- When the game is closed, calculate FP earned based on time away
- Use the player's current auto-play rate as the baseline
- Cap offline earnings (e.g. max 8 hours) so it doesn't feel broken
- Show a "welcome back" summary when the game reopens: time away, FP earned, any milestones hit
- Should feel like a gift, not a guilt trip for being away

## Design notes
- Active play > idle play > offline play in terms of FP rate. There should always be a reason to jump in, but never a punishment for stepping away.
- The auto-play AI should reflect the paddle's current upgrade level. A slow, small paddle plays worse on its own.
- Offline rewards need the save/load system from Progression System to work.

## Dependencies
- Progression System (FP economy, save/load)
- Ball Scaling (streak difficulty feeds into auto-play length)
