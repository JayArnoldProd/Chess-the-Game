# PRP-007: Multi-Frame AI Search + Settings Menu

**Date:** 2026-02-26  
**Status:** IMPLEMENTED  
**Priority:** High

## Overview

Convert the synchronous blocking AI search into a multi-frame state machine so the game remains responsive (cursor moves, animations play) while the AI thinks for extended periods. Also add a polished settings menu.

## Problem Statement

The previous AI implementation ran synchronously in a single Step call, blocking the entire game loop. Even with a 100ms hard cap, this caused noticeable UI freezes. For longer think times (10-30 seconds for grandmaster difficulty), the game would be completely unplayable.

## Solution Architecture

### Multi-Frame State Machine

The AI_Manager now uses a state machine:

```
IDLE → PREPARING → SEARCHING → EXECUTING → IDLE
```

**State Variables Added:**
- `ai_state` - Current state ("idle", "preparing", "searching", "executing")
- `ai_search_board` - Virtual board being searched
- `ai_search_world_state` - Complete world state (board + tiles + objects)
- `ai_search_moves[]` - Root moves to evaluate
- `ai_search_index` - Current root move being searched
- `ai_search_best_move` - Best move found so far
- `ai_search_best_score` - Best score found
- `ai_search_current_depth` - Current iterative deepening depth
- `ai_search_start_time` - Search start time (microseconds)
- `ai_search_frame_budget` - Max ms per frame (14ms for 60fps safety)
- `ai_thinking_dots` - For "Thinking..." animation

### State Flow

1. **IDLE** - Waits for AI turn, then transitions to PREPARING
2. **PREPARING** - Builds virtual world, generates root moves, orders them, then SEARCHING
3. **SEARCHING** - Each frame:
   - Process root moves within frame budget (14ms)
   - When depth complete, increment and reorder moves (best first)
   - When time limit reached, finalize and go to EXECUTING
   - **YIELDS** after frame budget - lets game loop run!
4. **EXECUTING** - Execute best move, return to IDLE

### Key Insight

The alpha-beta function (`ai_negamax_ab`) stays synchronous - we just call it for ONE root move at a time. Each call typically completes in a few ms, so we can process several per frame budget.

### Difficulty Settings (Updated)

```gml
Level 1 (Beginner): 0ms (instant, heuristic only)
Level 2 (Easy):     500ms (0.5 seconds)
Level 3 (Medium):   2000ms (2 seconds)
Level 4 (Hard):     10000ms (10 seconds)
Level 5 (Master):   30000ms (30 seconds)
```

The 100ms hard cap has been removed - multi-frame handles long searches gracefully.

## Files Modified

### AI_Manager/Create_0.gml
- Added state machine variables
- Added search statistics tracking
- Added thinking animation variables

### AI_Manager/Step_0.gml
- Complete rewrite to state machine architecture
- Frame budget enforcement with yield
- Iterative deepening within state machine
- Added `ai_finalize_search()` helper function

### AI_Manager/Draw_64.gml
- Live search progress display during thinking
- Progress bar showing time elapsed
- Current depth, move index, nodes searched
- Last search statistics when idle

### ai_set_difficulty_simple.gml
- Updated time limits (removed 100ms cap consideration)
- Added `ai_get_difficulty_name()` helper function
- Store difficulty level in `global.ai_difficulty_level`

### ai_search_iterative.gml
- Removed 100ms hard cap (now serves as fallback only)
- Main search is now in AI_Manager state machine

## Settings Menu (Polished)

### Features
- **F1** toggles settings menu open/close
- **ESC** also closes menu when open
- **F2** toggles AI debug display

### Menu Contents
1. **AI Difficulty** - 5 clickable buttons (1-5)
   - Shows current setting highlighted
   - Displays difficulty name and time limit
2. **Show AI Info** - Toggle button (ON/OFF)
   - Controls debug overlay visibility
3. **Current World** - Displays room name

### Files for Settings Menu

#### Game_Manager/Create_0.gml
- Added `settings_open` variable
- Added `show_ai_info` variable
- Added `global.ai_difficulty_level` tracking

#### Game_Manager/Draw_64.gml
- Added AI thinking indicator (top-right corner)
- Added settings menu overlay when open
- Difficulty buttons, toggle, world display

#### Game_Manager/KeyPress_112.gml (NEW)
- F1 reserved (settings use gear icon, no toggle)

#### Game_Manager/KeyPress_113.gml (NEW)
- F2 key handler - toggles AI debug display

#### Game_Manager/Mouse_6.gml (NEW)
- Global left click handler for settings menu
- Click outside menu closes it
- Click on buttons changes settings

#### Game_Manager/KeyPress_27.gml
- Modified to close settings menu when open

#### Game_Manager/Game_Manager.yy
- Registered new events (F2, Global Mouse)

### Input Blocking

When settings menu is open:
- `Tile_Obj/Mouse_7.gml` - Blocks tile clicks
- `Chess_Piece_Obj/Mouse_4.gml` - Blocks piece selection

## Visual Feedback

### During AI Thinking
1. "Thinking..." with animated dots (top-right corner)
2. Current depth and time shown
3. Full debug panel (left side) shows:
   - State machine status
   - Search progress bar
   - Nodes searched
   - Best score so far

### After Search Complete
- Last search statistics displayed
- Depth reached, nodes, time, score

## Testing Notes

1. **Responsiveness** - Cursor should move smoothly during AI thinking
2. **Long Searches** - Set difficulty to 5, verify game stays responsive for 30 seconds
3. **Settings Menu** - Gear icon opens/closes, click outside closes, buttons work
4. **Input Blocking** - Can't click pieces/tiles when menu open
5. **Difficulty Change** - Changing difficulty should take effect immediately

## Benefits

1. **No More Freezes** - Game loop runs every frame regardless of AI think time
2. **Scalable Difficulty** - Can now support very long think times (30+ seconds)
3. **Visual Feedback** - Players see AI is thinking with progress
4. **Debug Friendly** - Easy to adjust difficulty and view stats during play
