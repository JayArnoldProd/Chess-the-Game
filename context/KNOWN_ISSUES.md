# Chess-the-Game — Known Issues

**Last Updated:** 2026-02-27

---

## Status Key

| Icon | Status | Meaning |
|------|--------|---------|
| 🔴 | OPEN | Known bug, not yet fixed |
| 🟡 | FIXED (UNTESTED) | Code fix applied, needs playtesting |
| 🟢 | RESOLVED | Fixed and verified |

---

## Open Bugs

### #8 — Pawn Promotion No Choice 🔴
**Status:** Open (Low Priority)

**Description:** When a pawn reaches the opposite end, it automatically becomes a Queen. Standard chess allows the player to choose Queen, Rook, Bishop, or Knight.

**Location:** `Pawn_Obj/Step_0.gml`
```gml
instance_change(Queen_Obj, 1);
```

**Fix Needed:** Add UI popup for piece selection before transformation.

---

### #9 — Stepping Stone Edge Case 🔴
**Status:** Open (Rare)

**Description:** When AI lands on a stepping stone at the board edge, phase 1 sometimes finds 0 valid 8-directional moves. The sequence ends gracefully (no crash) but AI doesn't get the bonus move.

**Root Cause:** Tile detection at board edges can be unreliable due to position rounding.

**Workaround:** Graceful fallback already in place — sequence ends without bonus move.

---

### #30 — AI Phantom Diagonal Pawn Move 🔴
**Status:** Open (Unverified)

**Description:** Jay observed an enemy pawn making an illegal diagonal move to an empty square on the first map (~90% sure).

**Likely Root Cause:** En passant handling. The fallback path (`ai_get_legal_moves_safe` + `ai_pick_safe_move`) reads en passant moves from `valid_moves` but doesn't preserve the tag. `ai_execute_move_animated` has no en passant handling — doesn't remove the adjacent pawn.

**Possible Fixes:**
1. Add en passant execution to `ai_execute_move_animated` (destroy pawn at `[to_col, from_row]`)
2. Add en passant to virtual move generation
3. Filter en passant from `ai_get_legal_moves_safe` until properly supported

---

## Resolved Bugs

### Critical Fixes

| Bug | Description | Fix |
|-----|-------------|-----|
| Sliding check detection | Bishop/Rook/Queen only calculated `valid_moves` when selected, breaking check detection | Removed `selected_piece == self` guard from Step events |
| Castling through check | King could castle out of, through, and into check | Added 3 validation checks in `King_Obj/Step_0.gml` |
| AI stepping stone crash | AI didn't know what to do after landing on stepping stone | AI now directly sets up stepping stone state and handles phases via `ai_handle_stepping_stone_move()` |
| AI double-move | AI would cycle idle→preparing→executing before turn actually switched | Added `waiting_turn_switch` state that waits for `turn != 1` |

### AI Fixes

| Bug | Description | Fix |
|-----|-------------|-----|
| Reserved variable names | `score`, `board`, `depth`, `sign` are GML builtins | Renamed to `_score`, `_board`, `_depth`, `_sign` |
| Dead code bloat | 163 ai_* scripts cluttering project | Removed 127 unused scripts (now 36) |
| AI not world-aware | Ignored conveyors, water, void | Created `ai_world_effects.gml` with extensible mechanic system |
| AI moves into water | AI pieces drowned without consequence | Added water/void checks to `ai_execute_move_animated()` |
| AI slides over water | Bishop/Rook/Queen jumped over water tiles | Modified `ai_get_sliding_moves_virtual()` to check tile types |
| Cursor freeze | Game froze during AI thinking | Multi-frame state machine with 14ms frame budget |
| Conveyor direction | Belt direction inverted in AI simulation | Fixed `right_direction ? 1 : -1` |
| AI doesn't escape check | Made random move when in check | `ai_get_legal_moves_safe` now properly filters moves that leave king in check |
| AI pawn into void | AI pawn moved into trash can on Fear Factory | Added conveyor-push-into-hazard detection to `ai_is_tile_safe()` |
| Conveyor animation sync | AI started thinking while belts were animating | Added `Factory_Belt_Obj.animating` checks to idle and preparing states |

### Gameplay Fixes

| Bug | Description | Fix |
|-----|-------------|-----|
| Check not enforced | Could move into check | Added `move_leaves_king_in_check()` validation |
| No check indicator | No visual feedback for check | King pulses red, "CHECK!" text at top |
| Piece type corruption | Up/Down arrows cycled `piece_type` | Disabled debug `KeyPress_38/40` on `Chess_Piece_Obj` |
| AI stepping stone gives player control | Player could control AI pieces during stepping stone | Added `piece_type == 0` checks to stepping stone logic |

### UI Fixes

| Bug | Description | Fix |
|-----|-------------|-----|
| Debug text over board | AI debug drawn on left side over board | Moved to right side (gui_w - 200) |
| Settings gear not clickable | `Mouse_6` was Middle Button, not left click | Moved click handling to `Step_0.gml` |
| No volume control | Settings missing mute option | Added mute/unmute toggle button |
| Close button overlap | Close button overlapping Current World text | Increased panel height from 400→480 |

---

## Known Limitations

### Gameplay

| Limitation | Notes |
|------------|-------|
| No true checkmate detection | Game ends on king capture, not checkmate position |
| No piece choice on promotion | Always becomes Queen |
| No "Play as Black" option | Always white (player) vs black (AI) |
| No undo/redo | Moves cannot be undone |
| No move history | No algebraic notation display |

### AI

| Limitation | Notes |
|------------|-------|
| En passant partially supported | Virtual search may not simulate correctly |
| No opening book | AI plays from scratch every game |
| No endgame tablebase | Relies on evaluation in endgames |
| Stepping stone bonus simplistic | Only checks adjacency, not mobility calculation |

### Technical

| Limitation | Notes |
|------------|-------|
| Audio via Igor | Music/SFX may not play when launched via Igor CLI (works in IDE) |
| IDE version specific | Requires 2024.13.1.193 (2024.14 has prefab bug) |
| No mobile support | Desktop only (mouse input) |

---

## Bug Reporting

When finding new bugs, add them to `C:\Users\jayar\clawd\memory\chess-bugs.md` with:

1. **Bug number** (increment from last)
2. **Status** (🔴 OPEN)
3. **Description** (what happened)
4. **Reproduction steps** (if known)
5. **Suspected cause** (if any)
6. **World/Room** where it occurred

Example:
```markdown
| 31 | 🔴 | Knight captured own piece | 2026-02-28 | — | Occurred in Fear Factory, knight landed on same-color pawn |
```
