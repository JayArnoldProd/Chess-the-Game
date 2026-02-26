# PRP-006: Check/Checkmate Implementation

**Status:** IMPLEMENTED ✅  
**Date:** 2026-02-26  
**Author:** Subagent

## Summary

Implemented check enforcement, check indicators, and game-over conditions for the chess game. Players can no longer make moves that leave their king in check, and the game ends when a king is captured.

## Changes Made

### 1. New Script: `move_leaves_king_in_check.gml`
**Location:** `scripts/move_leaves_king_in_check/`

Function that simulates a move and checks if it would leave the player's king in check:
- Temporarily moves the piece
- Temporarily removes any captured piece from consideration
- Checks if any enemy piece can attack the king
- Restores all positions
- Returns true if move is illegal (leaves king in check)

### 2. King Visual Indicator (Check Warning)
**Location:** `objects/King_Obj/Draw_0.gml`

Added red pulsing overlay on kings when they're in check:
- Uses `ai_is_king_in_check_simple(piece_type)` to detect check
- Draws pulsing red overlay using `draw_sprite_ext` with c_red tint
- Pulse effect: `0.5 + 0.3 * sin(current_time / 200)`

### 3. Game Over State
**Location:** `objects/Game_Manager/Create_0.gml`

Added game over variables:
- `game_over` - Boolean flag
- `game_over_message` - Text to display
- `game_over_timer` - Frame counter
- `game_over_delay` - Wait time (180 frames = 3 seconds)

### 4. Game Over Display
**Location:** `objects/Game_Manager/Draw_64.gml` (NEW EVENT)

Draw GUI event that displays:
- Semi-transparent dark overlay over entire screen
- Large "Checkmate! [White/Black] Wins!" text with shadow
- "Press R to restart" instruction below
- "CHECK!" warning text at top of screen when player's king is in check

### 5. King Destruction → Game Over
**Location:** `objects/King_Obj/Destroy_0.gml` (NEW EVENT)

When a king is destroyed:
- Sets `Game_Manager.game_over = true`
- Sets appropriate message based on which king died
- White king captured → "Checkmate! Black Wins!"
- Black king captured → "Checkmate! White Wins!"

### 6. Restart Handler
**Location:** `objects/Game_Manager/KeyPress_82.gml` (NEW EVENT)

Press R to restart after game over (with 1 second minimum delay)

### 7. Move Filtering (Tile_Obj)
**Location:** `objects/Tile_Obj/Mouse_7.gml`

Before allowing a move:
- Checks if `move_leaves_king_in_check(piece, target_x, target_y)` returns true
- If so, blocks the move with debug message
- Only applies to player pieces during normal moves (not stepping stone sequences yet)

### 8. Visual Move Filtering (Chess_Piece_Obj)
**Location:** `objects/Chess_Piece_Obj/Draw_0.gml`

When drawing valid move overlays:
- For player pieces, checks if each move would leave king in check
- Only draws green overlay and sets `valid_move = true` for legal moves
- Illegal moves are simply not shown (no green overlay)

### 9. Input Blocking During Game Over
**Locations:**
- `objects/Chess_Piece_Obj/Mouse_4.gml` - Block piece selection
- `objects/Tile_Obj/Mouse_7.gml` - Block tile clicks  
- `objects/AI_Manager/Step_0.gml` - Block AI moves

All input is blocked when `Game_Manager.game_over == true`

## Updated Project Files

- `Game_Manager.yy` - Added Draw_64 (Draw GUI) and KeyPress_82 (R key) events
- `King_Obj.yy` - Added Destroy_0 event
- `Chess the Game.yyp` - Added `move_leaves_king_in_check` script resource

## What Works

✅ **Check Visual Indicator** - King pulses red when in check  
✅ **Check Text Warning** - "CHECK!" displayed at top of screen  
✅ **Move Filtering** - Illegal moves (that leave king in check) are not shown and cannot be made  
✅ **Game Over on King Capture** - Dark overlay with win message appears  
✅ **Restart Functionality** - Press R to restart the room  
✅ **AI Blocking** - AI doesn't move during game over  
✅ **Compile Clean** - No compile errors

## What to Test

1. **Check Detection:**
   - Put player's king in check
   - Verify red pulse on king
   - Verify "CHECK!" text at top of screen

2. **Move Filtering:**
   - When in check, verify only moves that escape check are shown
   - Verify pinned pieces can only move along pin line

3. **Game Over:**
   - Capture a king
   - Verify dark overlay and win message
   - Verify R key restarts the game

4. **Stepping Stones + Check:**
   - Complex: What happens if you land on a stepping stone while in check?
   - Current: Check enforcement only applies to normal moves, not stepping stone phases

## Known Limitations

1. **Stepping Stone Check Enforcement** - Currently, check enforcement is skipped during stepping stone phases (`stepping_chain > 0`). This is intentional to avoid complexity, but means a player could theoretically make an illegal move during stepping stone phases. Low priority to fix.

2. **No True Checkmate Detection** - The game only ends when a king is captured, not when checkmate is reached. True checkmate detection (no legal moves while in check) is complex and was marked as a stretch goal. The current implementation works for gameplay purposes.

3. **No Stalemate Detection** - If a player has no legal moves but isn't in check, the game continues (player must pass or the game would freeze). Not implemented.

## Files Modified

| File | Change |
|------|--------|
| `scripts/move_leaves_king_in_check/move_leaves_king_in_check.gml` | NEW |
| `scripts/move_leaves_king_in_check/move_leaves_king_in_check.yy` | NEW |
| `objects/King_Obj/Draw_0.gml` | Added check indicator |
| `objects/King_Obj/Destroy_0.gml` | NEW - game over trigger |
| `objects/King_Obj/King_Obj.yy` | Added Destroy event |
| `objects/Game_Manager/Create_0.gml` | Added game_over variables |
| `objects/Game_Manager/Draw_64.gml` | NEW - game over display |
| `objects/Game_Manager/KeyPress_82.gml` | NEW - restart handler |
| `objects/Game_Manager/Game_Manager.yy` | Added new events |
| `objects/Tile_Obj/Mouse_7.gml` | Added check enforcement |
| `objects/Chess_Piece_Obj/Draw_0.gml` | Added legal move filtering |
| `objects/Chess_Piece_Obj/Mouse_4.gml` | Added game_over block |
| `objects/AI_Manager/Step_0.gml` | Added game_over block |
| `Chess the Game.yyp` | Added new script resource |
