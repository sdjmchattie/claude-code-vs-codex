# Claude Code vs Codex

A coding comparison between **Claude Code** (Anthropic, using Opus 4.6) and **Codex** (OpenAI, using gpt-5.3-codex) — both the best models available from their respective providers at the time of testing.

The task given to each: recreate the classic QBasic GORILLAS.BAS game in Godot 4.5.1, with destructible terrain and banana projectile physics.

## Play the Games

| | Play |
| --- | --- |
| **Claude Code** | [stuart.mchattie.net/claude-code-vs-codex/claude-code/](https://stuart.mchattie.net/claude-code-vs-codex/claude-code/) |
| **Codex** | [stuart.mchattie.net/claude-code-vs-codex/codex/](https://stuart.mchattie.net/claude-code-vs-codex/codex/) |

## Session Transcripts

The full agentic sessions are recorded in the root of this repo:

- [claude_code_session.txt](claude_code_session.txt) — Claude Code's session
- [codex_session.txt](codex_session.txt) — Codex's session

Both were given the same initial prompt:

> *Do you remember the game for Quick Basic with gorillas hurling bananas across a city scape? I want to recreate that in Godot and support dynamic generation of the city skyline. However, I'm happy to use a constant cityscape while getting the banana flight and explosion correct if that's easier. Ask questions.*

## Godot Projects

The generated Godot 4.5.1 projects are in:

- [Claude Code/](Claude%20Code/) — output from Claude Code
- [Codex/](Codex/) — output from Codex

## How They Approached It

### Claude Code (Opus 4.6)

Claude Code asked all 9 clarifying questions upfront in a single prompt, then presented an implementation plan and executed it in one pass. It chose a **monolithic architecture** closely mirroring the spirit of the original BASIC program:

- Single scene (`main.tscn`) + single script (`main.gd`, ~400–500 lines)
- 640×480 viewport with nearest-neighbour filtering for a retro look
- City skyline drawn procedurally onto an `Image` → `ImageTexture` on a `Sprite2D`
- Terrain destruction by directly manipulating image pixels and re-uploading via `ImageTexture.update()`
- Collision detection by checking pixel alpha values at the banana's position
- Projectile physics using parametric equations from the original GORILLA.BAS (not physics engine integration)
- Everything drawn programmatically — no external assets

### Codex (gpt-5.3-codex medium)

Codex asked **9 clarifying questions** spread across three rounds of 3 before proposing a plan, then implemented it. It chose a **component-based architecture**:

- Multiple scenes and scripts across `scenes/`, `scripts/`, and `configs/` directories
- `GameController`, `HUD`, `ExplosionSystem`, `WindSystem`, `BananaProjectile`, `Building`, `PlayerController`, `FixedSkylineProvider`
- `RigidBody2D` for banana physics with wind applied as a continuous force
- Destructible buildings using bitmap pixel manipulation with `BitMap.opaque_to_polygons()` to regenerate collision shapes after each crater — meaning projectiles can pass through previously blasted holes
- `MatchConfig` resource for tunable game parameters
- Designed with an `ISkylineProvider`-style interface to allow swapping in procedural generation later

## Key Differences

| | Claude Code | Codex |
| --- | --- | --- |
| **Architecture** | Monolithic (1 scene, 1 script) | Component-based (multiple scenes/scripts) |
| **Questions asked** | 9 (all at once) | 9 (in 3 rounds of 3) |
| **Physics** | Parametric equations | RigidBody2D + forces |
| **Collision** | Pixel alpha sampling | Polygon colliders rebuilt after each crater |
| **Viewport** | 640×480 (retro) | Default |
| **Skyline** | Procedural (immediate) | Fixed with provider interface for future procedural |
| **Bugs fixed after initial build** | 0 (session ended after plan + implementation) | 2 (self-hit on launch, player 2 off-screen) |
