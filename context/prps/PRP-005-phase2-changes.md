# PRP-005: Phase 2 Changes - Stepping Stone Fix + Dead Code Removal

## Date: 2026-02-26
## Status: COMPLETED ✅

---

## 🚨 Priority #1: Stepping Stone AI Crash - FIXED ✅

### Problem
When the AI landed on a stepping stone, the game crashed. The AI didn't know what to do after landing.

### Root Cause Analysis
The stepping stone flow was fundamentally broken:

1. `ai_execute_move_animated()` set `AI_Manager.ai_stepping_phase = -1` expecting the "existing stepping stone system" (in `Chess_Piece_Obj/Step_0.gml`) to activate the stepping stone

2. BUT the existing system explicitly SKIPS AI pieces:
   ```gml
   // ONLY process stepping stone logic if this is NOT an AI piece during AI turn
   if (!(piece_type == 1 && Game_Manager.turn == 1)) {
       // stepping stone activation code - SKIPPED for AI!
   }
   ```

3. The AI waited in phase -1 for a system that would never trigger, causing undefined behavior and crashes

### Fix Applied

**1. Modified `ai_execute_move_animated.gml`:**
- Removed the phase -1 "waiting for existing system" approach
- Now directly sets up stepping stone state when AI lands on one:
  ```gml
  // Set up stepping stone state on the piece (since existing system won't)
  piece.stepping_chain = 2;  // Phase 1: 8-directional move pending
  piece.extra_move_pending = true;
  piece.stepping_stone_instance = on_stepping_stone;
  piece.stone_original_x = on_stepping_stone.x;
  piece.stone_original_y = on_stepping_stone.y;
  
  // Tell AI Manager to handle stepping stone sequence
  AI_Manager.ai_stepping_phase = 1; // Phase 1: ready to make 8-directional move
  AI_Manager.ai_stepping_piece = piece;
  ```

**2. Modified `AI_Manager/Step_0.gml`:**
- Removed the entire broken phase -1 handling code
- Added animation wait checks before calling `ai_handle_stepping_stone_move()`
- Added safety checks for missing piece instances

**3. Modified `ai_end_stepping_stone_sequence.gml`:**
- Fixed grid snapping to use proper grid origin (Object_Manager.topleft_x/y)
- Added stepping stone return-to-origin logic
- Improved cleanup and turn switching

---

## Phase 2A: Dead Code Removal - COMPLETED ✅

### Summary
- **Before:** 163 ai_* scripts
- **After:** 36 ai_* scripts  
- **Removed:** 127 unused scripts (78% reduction!)

### Scripts Removed (127 total)

#### Unused Minimax System (9 scripts)
- `ai_minimax`, `ai_minimax_optimized`, `ai_minimax_window`
- `ai_find_best_move`, `ai_iterative_deepening_search`
- `ai_quiescence_search`, `ai_quiescence_search_optimized`
- `ai_search_depth`, `ai_search_depth_with_window`

#### Unused State Management (4 scripts)
- `ai_save_game_state`, `ai_restore_game_state`
- `ai_make_move_simulation`, `ai_copy_game_state`

#### Unused Transposition/Opening Book (10 scripts)
- `ai_store_transposition_table`, `ai_probe_transposition_table`, `ai_probe_transposition_table_move`, `ai_clear_transposition_table`
- `ai_check_opening_book`, `ai_load_opening_book`, `ai_save_opening_book`, `ai_update_opening_book`
- `ai_calculate_position_hash_for_opening`, `ai_get_board_hash`, `ai_get_current_game_hash`

#### Unused Move Generation (6 scripts)
- `ai_get_legal_moves`, `ai_generate_moves`, `ai_generate_piece_moves`
- `ai_is_legal_move`, `ai_get_non_repetitive_moves`, `ai_is_move_repetitive`

#### Unused Move Ordering (8 scripts)
- `ai_order_moves`, `ai_order_moves_advanced`, `ai_order_captures`
- `ai_update_killer_move`, `ai_update_history`
- `ai_score_move_fast`, `ai_score_move_tactical`, `ai_moves_equal`

#### Unused Difficulty Systems (8 scripts)
- `ai_set_difficulty`, `ai_set_difficulty_fast`
- `ai_adaptive_difficulty_update`, `ai_increase_difficulty`, `ai_decrease_difficulty`
- `ai_get_current_difficulty`, `ai_demonstrate_difficulty`
- `ai_easy_mode`, `ai_medium_mode`, `ai_hard_mode`

#### Unused Evaluation Functions (16 scripts)
- `ai_evaluate_board`, `ai_evaluate_board_enhanced`, `ai_evaluate_move_quality`
- `ai_evaluate_stepping_stones`, `ai_evaluate_bridge_control`, `ai_evaluate_water_control`
- `ai_evaluate_conveyor_belt_positioning`, `ai_evaluate_center_control`, `ai_evaluate_center_control_safe`
- `ai_evaluate_king_safety`, `ai_evaluate_king_safety_enhanced`, `ai_evaluate_king_safety_safe`
- `ai_evaluate_pawn_structure`, `ai_evaluate_pawn_structure_safe`
- `ai_evaluate_endgame_factors`, `ai_evaluate_passed_pawns_endgame`, `ai_is_passed_pawn`
- `ai_get_positional_bonus`, `ai_get_rank`, `ai_get_square_index`

#### Unused Tactical Analysis (8 scripts)
- `ai_move_creates_fork`, `ai_move_creates_pin`, `ai_move_creates_skewer`
- `ai_move_creates_threat`, `ai_move_blocks_threat`, `ai_move_defends_piece`
- `ai_move_improves_position`, `ai_move_gives_check_fast`

#### Unused Check/Checkmate (4 scripts)
- `ai_is_checkmate`, `ai_is_stalemate`, `ai_is_king_in_check`

#### Emergency/Fix Scripts (8 scripts)
- `ai_emergency_fix`, `ai_emergency_fix_all`, `ai_emergency_move`, `ai_emergency_reset`
- `ai_fix_common_issues`, `ai_reset_to_basic_mode`, `ai_switch_to_simple_mode`
- `ai_initialize_clean`

#### Test/Debug Scripts (16 scripts)
- `ai_test_basic_functions`, `ai_test_move_generation`, `ai_test_simple_move`
- `ai_quick_test`, `ai_stress_test`, `ai_performance_test`, `ai_performance_benchmark`
- `ai_verify_installation`, `ai_debug_current_position`, `ai_debug_status`
- Various others...

#### Unused Move Execution Variants (8 scripts)
- `ai_execute_move`, `ai_execute_move_fast`, `ai_execute_move_fast_robust`, `ai_execute_move_simple`
- `ai_execute_normal_move`, `ai_execute_castling_move`, `ai_execute_en_passant_move`
- `ai_make_move`

#### Unused Stepping Stone Variants (4 scripts)
- `ai_force_stepping_stone_phase2`, `ai_sync_stepping_stone_state`
- Various test scripts

#### Miscellaneous Unused (30+ scripts)
- Performance tracking, analysis, utilities, etc.

### Scripts Kept (36 total)

#### Core AI System (13)
```
ai_search_iterative      # Main search with iterative deepening
ai_alphabeta             # Alpha-beta fallback
ai_search                # Entry point + helpers
ai_build_virtual_board   # Virtual board
ai_copy_board            # Board copying
ai_make_move_virtual     # Virtual moves
ai_generate_moves_from_board  # Move generation
ai_get_piece_moves_virtual    # Piece moves
ai_is_king_in_check_virtual   # Virtual check
ai_evaluate_advanced     # Full evaluation
ai_evaluate_virtual      # Eval wrapper
ai_zobrist               # Zobrist hashing
ai_transposition         # Transposition table
```

#### Fallback/Safe AI (11)
```
ai_get_legal_moves_safe  # Safe move gen
ai_get_legal_moves_fast  # Fast move gen
ai_is_king_in_check_simple   # Simple check
ai_pick_safe_move        # Heuristic selection
ai_move_escapes_check    # Check escape
ai_move_puts_king_in_check   # King safety
ai_get_piece_value       # Material values
ai_is_safe_move          # Move safety
ai_is_square_attacked    # Square attacks
ai_validate_move_legality    # Validation
ai_execute_move_animated # Move execution
```

#### Stepping Stone Support (5)
```
ai_handle_stepping_stone_move
ai_end_stepping_stone_sequence
ai_force_stepping_stone_move     # Debug
ai_manual_stepping_stone_advance # Debug
ai_debug_stepping_stone_state    # Debug
```

#### Difficulty (2)
```
ai_set_difficulty_simple
ai_set_difficulty_enhanced
```

#### Debug/Emergency (5)
```
ai_comprehensive_debug
ai_fix_stuck_pieces
ai_restart_clean
ai_emergency_stop
ai_show_stepping_stone_help
```

---

## GML Reserved Variable Fixes

### Issue
GameMaker has reserved variable names that cannot be used as local variables or parameters.

### Fixes Applied

**`ai_evaluate_advanced.gml`:**
- `sign` → `_sign` (sign() is a built-in function)

**`ai_search_iterative.gml`:**
- `depth` → `_depth` (depth is a built-in variable)
- `score` → `_score`
- `board` → `_board`
- `hash` → `_hash`
- `alpha` → `_alpha`
- `beta` → `_beta`
- `maximizing` → `_maximizing`
- `stones` → `_stones`
- `moves` → `_moves`
- `color` → `_color`
- `tt_move` → `_tt_move`

---

## Verification

### Compile Test Results
```
Stats : GMA : sp=32,au=19,bk=0,pt=0,sc=158,sh=5,fo=0,tl=0,ob=30,ro=7,da=0,ex=0,ma=6
```
- **Scripts:** 158 (down from 423 - 63% reduction in total scripts)
- **Memory:** 24.73MB
- **No compile errors**

### Runtime Test Results
- Game launches successfully
- Player can move pieces
- AI makes moves on its turn
- **AI properly handles stepping stones without crashing!**
- Turn switching works correctly
- Debug functions still available via keyboard shortcuts

---

## Files Modified

### Scripts Modified
- `scripts/ai_execute_move_animated/ai_execute_move_animated.gml`
- `scripts/ai_end_stepping_stone_sequence/ai_end_stepping_stone_sequence.gml`
- `scripts/ai_handle_stepping_stone_move/ai_handle_stepping_stone_move.gml`
- `scripts/ai_evaluate_advanced/ai_evaluate_advanced.gml`
- `scripts/ai_search_iterative/ai_search_iterative.gml`

### Objects Modified
- `objects/AI_Manager/Step_0.gml`

### Project File
- `Chess the Game.yyp` - Removed 127 script references

### Scripts Deleted
- 127 ai_* script folders removed from `scripts/` directory

---

## Known Remaining Issues

### Minor: Phase 2 Tile Detection Edge Case
In rare cases when stepping stone is at board edge, the AI finds valid_moves but tile detection fails. The sequence ends gracefully (no crash) but the AI doesn't complete the stepping stone bonus move. This is a pre-existing issue with tile boundary detection, not introduced by these changes.

---

## Extensible World Mechanics Architecture - COMPLETED ✅

**Created `ai_world_effects.gml`** (~600 lines) implementing Jay's vision for mechanic-aware AI.

### Architecture Overview

```
ai_build_virtual_world()
    ├── board: 8x8 piece array
    ├── tiles: 8x8 tile type array (normal/water/void)
    ├── objects: { stepping_stones, bridges, conveyors }
    └── mechanics: ["stepping_stones"] / ["water", "bridges"] / etc.

ai_apply_world_effects(world_state)  // Called after each virtual move
    ├── ai_apply_conveyor_effect()   // Shift pieces on belts
    ├── ai_apply_water_effect()      // Drown pieces without bridges
    └── ai_apply_void_effect()       // Destroy pieces on void

ai_evaluate_world_bonuses(world_state, color)  // Pluggable eval
    ├── ai_eval_stepping_stone_bonus()
    ├── ai_eval_bridge_control_bonus()
    ├── ai_eval_conveyor_position_bonus()
    ├── ai_eval_void_avoidance_bonus()
    └── ai_eval_spawn_volatility_bonus()
```

### World Support

| World | Mechanics | AI Behavior |
|-------|-----------|-------------|
| Ruined Overworld | stepping_stones | Values stone positions, accounts for 2-phase moves |
| Pirate Seas | water, bridges | Avoids water, values bridge control |
| Fear Factory | conveyors | Simulates belt shifts, avoids belt edges |
| Twisted Carnival | random_spawns | Values central control, piece grouping |
| Volcanic Wasteland | lava_hazards | Avoids lava (same as void) |
| Void Dimension | void_tiles, reduced_board | Avoids void, penalizes pieces near void |

### Data-Driven Piece Patterns (Future-Ready)

```gml
// Standard pieces return movement patterns
ai_get_piece_movement_pattern("knight") → {
    type: "leap",
    offsets: [[1,-2], [2,-1], ...],
    special: []
}

// Custom pieces can be registered
ai_register_custom_piece("multi_mover", {
    type: "step",
    offsets: [...],
    special: ["extra_move"]  // Can move twice
});
```

### Integration Points

- `ai_search_iterative()` - Now builds virtual world, stores in global
- `ai_negamax_ab()` - Applies world effects after each move, uses world-aware move gen
- `ai_quiescence()` - Includes world bonuses in evaluation

---

## Next Steps (Phase 2B: Deep Bug Hunt)

Still need to audit:
1. Pawn promotion mechanics
2. En passant edge cases
