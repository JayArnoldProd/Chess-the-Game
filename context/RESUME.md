# Chess-the-Game — Resume Guide

**Last Updated:** 2026-02-26  
**Last Session:** AI overhaul, bug sweep, settings menu, world mechanics  
**State:** Playable and stable. Ready for developer review.

---

## Quick Start for Next Session

1. Read `context/RESUME.md` (this file)
2. Read Arnold's memory: `C:\Users\jayar\clawd\memory\chess-the-game.md`
3. Read bug tracker: `C:\Users\jayar\clawd\memory\chess-bugs.md`
4. Read Igor setup: `C:\Users\jayar\clawd\memory\gamemaker-igor-setup.md`
5. Check PRPs in `context/prps/` for architectural decisions

## Project Location
- **Repo:** `C:\Users\jayar\Documents\GitHub\Chess-the-Game`
- **Project file:** `Chess the Game.yyp`
- **Engine:** GameMaker Studio 2 (IDE 2024.13.1.193, Runtime 2024.13.1.242)
- **Language:** GML (modern — structs, method(), functions as first-class)

## Build & Test Pipeline
```powershell
$igor = "C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.13.1.242\bin\igor\windows\x64\Igor.exe"
$project = "C:\Users\jayar\Documents\GitHub\Chess-the-Game\Chess the Game.yyp"
$runtimePath = "C:\ProgramData\GameMakerStudio2\Cache\runtimes\runtime-2024.13.1.242"
$userFolder = "C:\Users\jayar\AppData\Roaming\GameMakerStudio2\jayarnoldproduces_1544617"
$cache = "C:\Users\jayar\clawd\temp\gms2-build\cache"
$temp = "C:\Users\jayar\clawd\temp\gms2-build\temp"
& $igor --project="$project" --runtimePath="$runtimePath" --user="$userFolder" --cache="$cache" --temp="$temp" -r=VM -j=8 --ignorecache windows Run
```
- Always compile-test after GML changes
- GML reserved names to avoid: `score`, `board`, `health`, `lives`, `x`, `y`, `depth`, `sign` — prefix with `_`
- Game launches on Jay's machine via Igor `windows Run`

## What Was Done (2026-02-26)

### AI Overhaul (from scratch → grandmaster level)
- **Virtual board search** — No instance manipulation during search; pure arrays/structs
- **Multi-frame state machine** — IDLE→PREPARING→SEARCHING→EXECUTING with 14ms frame budget
- **Iterative deepening** with alpha-beta pruning, transposition tables, Zobrist hashing
- **PVS + LMR** — Principal Variation Search + Late Move Reductions
- **Quiescence search** — Captures-only extension to avoid horizon effect
- **5 difficulty levels** — Instant / 500ms / 2s / 10s / 30s (Grandmaster)
- **Dead code cleanup** — 127 unused AI scripts removed (423→158 total scripts)

### World Mechanics Awareness
- **Stepping stones** — AI handles full 2-phase sequence (8-dir + normal move)
- **Water/bridges** — AI won't move into water; sliding pieces stop at water edge
- **Conveyor belts** — AI waits for belt animation, evacuates pieces from belt edges
- **Void tiles** — AI avoids void; sliding pieces stop at void
- **Lava** — Treated as void
- **Carnival spawns** — Evaluation bonus for central control

### Core Chess Fixes
- Sliding piece check detection (Bishop/Rook/Queen)
- Castling through/into/out-of check blocked
- Check visual indicators (king pulses red, "CHECK!" text)
- Game over on king capture with restart (Press R)
- Move filtering — illegal moves not shown or selectable

### UI/UX
- **Settings menu** — Gear icon (top-right), opens panel with difficulty + volume toggle
- **Debug overlay** — F2 toggles compact horizontal display (off by default)
- **AI pauses** when settings open
- **Up/Down arrows disabled** — Were corrupting piece types (dev debug leftover)

### Bug Fixes (27 tracked in bug tracker)
- Double-move prevention (`waiting_turn_switch` state)
- Conveyor belt animation sync
- Pawn capture rules in stepping stone phase 2
- Water/void hazard destruction for AI pieces
- Multiple crash fixes (captured piece refs, stepping stone edge cases)
- Settings gear click fix (was Middle Mouse Button, moved to Step_0)

## What's Left (Known Issues)

### Open Bugs
- **#8** 🔴 Pawn promotion always gives Queen — no piece choice (low priority)
- **#9** 🔴 Stepping stone phase 2 tile detection edge case at board edges (rare, no crash)

### Stretch Goals
- **True checkmate/stalemate detection** — Currently king capture = game over; position-based detection would be more chess-accurate
- **Play as Black** — Up/Down arrow keys were cycling piece_type (disabled). Proper implementation would need pawn direction awareness
- **Audio** — Music/SFX not playing via Igor launch (works in IDE, likely Igor quirk)
- **Pawn promotion UI** — Let player choose Queen/Rook/Bishop/Knight

## Architecture Notes

### AI State Machine (AI_Manager/Step_0.gml)
```
IDLE → PREPARING → SEARCHING → EXECUTING → WAITING_TURN_SWITCH → IDLE
```
- **IDLE:** Waits for turn=1, no animations, no belts animating
- **PREPARING:** Builds virtual world, generates/orders root moves, detects checkmate/stalemate
- **SEARCHING:** Processes root moves within 14ms frame budget, yields to game loop
- **EXECUTING:** Converts virtual move to real, handles stepping stones/castling/hazards
- **WAITING_TURN_SWITCH:** Waits for `Game_Manager.turn` to flip to 0 (prevents double-move)

### World Effects System (ai_world_effects.gml)
- `ai_build_virtual_world()` → board + tiles + objects (stones, bridges, conveyors)
- `ai_apply_board_world_effects()` → called after each virtual move in search
- `ai_evaluate_world_bonuses()` → pluggable per-world evaluation bonuses
- `ai_is_tile_safe()` → filters void/water (conveyor danger handled by search tree)

### Key Files
| File | Purpose |
|------|---------|
| `AI_Manager/Step_0.gml` | Main AI state machine (~420 lines) |
| `AI_Manager/Draw_64.gml` | Debug overlay (compact horizontal) |
| `Game_Manager/Step_0.gml` | Settings click handling |
| `Game_Manager/Draw_64.gml` | Settings panel + gear icon + game over |
| `ai_search_iterative.gml` | Negamax + alpha-beta + TT + quiescence |
| `ai_world_effects.gml` | World mechanics simulation (~600 lines) |
| `ai_execute_move_animated.gml` | Move execution with stepping stones/hazards |
| `ai_handle_stepping_stone_move.gml` | AI stepping stone phase handler |
| `ai_get_piece_moves_virtual.gml` | Virtual move generation (world-aware) |

### PRPs
- `PRP-001` — AI dead code cleanup
- `PRP-002` — AI architecture redesign
- `PRP-003` — Core chess logic audit
- `PRP-004` — Bug fixes summary (session 1)
- `PRP-005` — Phase 2 changes (session 2)
- `PRP-006` — Check/checkmate implementation
- `PRP-007` — Multi-frame search architecture

## Team
- **Jay Arnold** — Project lead, developer
- **Bob ("Monkey Manc")** — Game designer, original creator
- **Arnold (AI)** — AI overhaul, bug fixes, documentation
