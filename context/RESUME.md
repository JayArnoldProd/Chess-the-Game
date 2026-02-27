# Chess-the-Game — Resume Guide

**Last Updated:** 2026-02-27  
**Last Session:** AI overhaul, bug sweep, settings menu, world mechanics  
**State:** Playable and stable. Ready for developer review.

---

## Quick Start for Next Session

1. **Read this file** (`context/RESUME.md`)
2. **Read the context docs:**
   - `context/ARCHITECTURE.md` — System overview, object hierarchy, turn flow
   - `context/GAME_MECHANICS.md` — Chess rules, world mechanics, UI
   - `context/AI_SYSTEM.md` — AI search, evaluation, world awareness
   - `context/OBJECTS_REFERENCE.md` — Quick reference for all objects
   - `context/KNOWN_ISSUES.md` — Open bugs, resolved bugs, limitations
   - `context/BUILD_GUIDE.md` — How to compile and run
3. **Read Arnold's memory files:**
   - `C:\Users\jayar\clawd\memory\chess-the-game.md` — Session history
   - `C:\Users\jayar\clawd\memory\chess-bugs.md` — Bug tracker
   - `C:\Users\jayar\clawd\memory\gamemaker-igor-setup.md` — Build setup
4. **Check PRPs** in `context/prps/` for architectural decisions

---

## Project Overview

| Item | Value |
|------|-------|
| **Repo** | `C:\Users\jayar\Documents\GitHub\Chess-the-Game` |
| **Project File** | `Chess the Game.yyp` |
| **Engine** | GameMaker Studio 2 |
| **IDE Version** | 2024.13.1.193 (required — 2024.14 has prefab bug) |
| **Runtime** | 2024.13.1.242 |
| **Language** | GML (modern — structs, methods, first-class functions) |

---

## Build & Test (Igor CLI)

```powershell
$igor = "C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.13.1.242\bin\igor\windows\x64\Igor.exe"
$project = "C:\Users\jayar\Documents\GitHub\Chess-the-Game\Chess the Game.yyp"
$runtimePath = "C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.13.1.242"
$userFolder = "C:\Users\jayar\AppData\Roaming\GameMakerStudio2\jayarnoldproduces_1544617"
$cache = "C:\Users\jayar\clawd\temp\gms2-build\cache"
$temp = "C:\Users\jayar\clawd\temp\gms2-build\temp"
& $igor --project="$project" --runtimePath="$runtimePath" --user="$userFolder" --cache="$cache" --temp="$temp" -r=VM -j=8 --ignorecache windows Run
```

**Always compile-test after GML changes** — catches reserved variable names, syntax errors, etc.

---

## What Was Done (2026-02-26)

### AI Overhaul (from scratch → grandmaster level)
- **Multi-frame state machine** — IDLE→PREPARING→SEARCHING→EXECUTING→WAITING_TURN_SWITCH
- **14ms frame budget** — Game stays responsive during 30-second searches
- **Iterative deepening** with alpha-beta, transposition tables, Zobrist hashing
- **PVS + LMR** — Principal Variation Search + Late Move Reductions
- **Quiescence search** — Captures-only extension to avoid horizon effect
- **5 difficulty levels** — Instant / 500ms / 2s / 10s / 30s (Grandmaster)
- **Dead code cleanup** — 127 unused AI scripts removed (423→158 total)

### World Mechanics Awareness
- **Stepping stones** — AI handles full 2-phase sequence
- **Water/bridges** — AI won't move into water; sliding pieces stop at water
- **Conveyor belts** — AI waits for animation, penalizes belt edge positions
- **Void tiles** — AI avoids void; sliding pieces stop at void

### Core Chess Fixes
- Sliding piece check detection (Bishop/Rook/Queen)
- Castling through/into/out-of check blocked
- Check visual indicators (king pulses red, "CHECK!" text)
- Game over on king capture with restart

### UI/UX
- **Settings menu** — Gear icon (top-right), difficulty + volume toggle
- **Debug overlay** — F2 toggles compact display
- **AI pauses** when settings open

### Bug Fixes (27+ tracked)
See `context/KNOWN_ISSUES.md` for full list.

---

## What's Left (Known Issues)

### Open Bugs
- **#8** — Pawn promotion always Queen (no choice)
- **#9** — Stepping stone edge case (rare)
- **#30** — AI phantom diagonal pawn move (unverified)

### Stretch Goals
- True checkmate/stalemate detection (currently king capture = game over)
- Pawn promotion UI (choose piece)
- Play as Black option
- Opening book / endgame tablebase

---

## Architecture Summary

### AI State Machine
```
IDLE → PREPARING → SEARCHING → EXECUTING → WAITING_TURN_SWITCH → IDLE
```

### Key Files
| File | Purpose |
|------|---------|
| `AI_Manager/Step_0.gml` | Main AI loop (~420 lines) |
| `ai_search_iterative.gml` | Negamax + alpha-beta + TT |
| `ai_world_effects.gml` | World mechanics simulation (~600 lines) |
| `ai_execute_move_animated.gml` | Move execution with stepping stones |
| `Game_Manager/Draw_64.gml` | Settings panel + UI |
| `Chess_Piece_Obj/Step_0.gml` | Movement animation + stepping stones |
| `Tile_Obj/Mouse_7.gml` | Move execution |

### Object Hierarchy
```
Managers: Game_Manager, AI_Manager, Board_Manager, Object_Manager
Pieces: Chess_Piece_Obj (parent) → Pawn, Knight, Bishop, Rook, Queen, King
Tiles: Tile_Obj (parent) → Tile_Black, Tile_White, Tile_Void
World: Stepping_Stone_Obj, Bridge_Obj, Factory_Belt_Obj
```

---

## Documentation Files

| File | Description |
|------|-------------|
| `ARCHITECTURE.md` | System overview, object hierarchy, turn flow, room structure |
| `GAME_MECHANICS.md` | Chess rules, world mechanics (stepping stones, water, conveyors, void) |
| `AI_SYSTEM.md` | Virtual board, multi-frame search, evaluation, world awareness |
| `OBJECTS_REFERENCE.md` | Quick reference for every object with variables and events |
| `KNOWN_ISSUES.md` | Open bugs, resolved bugs, known limitations |
| `BUILD_GUIDE.md` | Igor CLI setup, common errors, GML gotchas |
| `RESUME.md` | This file — quick start guide |

### Design Docs
- `design-docs/enemy-boss-system-spec.md` — Future enemy/boss system

### PRPs (Project Review Proposals)
- `PRP-001` — AI dead code cleanup
- `PRP-002` — AI architecture redesign
- `PRP-003` — Core chess logic audit
- `PRP-004` — Bug fixes summary (session 1)
- `PRP-005` — Phase 2 changes (session 2)
- `PRP-006` — Check/checkmate implementation
- `PRP-007` — Multi-frame search architecture

---

## Team

- **Jay Arnold** — Project lead, developer
- **Bob ("Monkey Manc")** — Game designer, original creator
- **Arnold (AI)** — AI overhaul, bug fixes, documentation

---

## GML Quick Reference

### Reserved Names to Avoid
Prefix with `_`: `score`, `board`, `depth`, `sign`, `health`, `x`, `y`

### Common Patterns
```gml
// Instance check
if (instance_exists(obj)) { ... }

// Tile at position
var tile = instance_position(x + tile_size/4, y + tile_size/4, Tile_Obj);

// Animation
if (is_moving) {
    move_progress += 1 / move_duration;
    x = lerp(move_start_x, move_target_x, easeInOutQuad(move_progress));
}
```

---

## Controls

| Control | Action |
|---------|--------|
| Left Click | Select piece / Move |
| Left/Right Arrows | Navigate worlds |
| R | Restart level |
| F1 | Toggle settings |
| F2 | Toggle AI debug |
| ESC | Close settings |
