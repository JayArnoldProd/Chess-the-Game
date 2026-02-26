# PRP-001: AI Cleanup & Dead Code Removal

## Overview
The AI codebase has grown to 150+ scripts, most of which are unused, redundant, or broken. This PRP catalogs all scripts and provides a plan for safe removal.

## Current State
- **Total ai_* scripts**: 150
- **Actually used from core game**: ~15-20
- **Definitely dead**: ~100+
- **Uncertain/indirect**: ~30

## Script Catalog

### ✅ KEEP - Actually Used (Called from AI_Manager or other core code)

| Script | Called From | Purpose |
|--------|-------------|---------|
| `ai_get_legal_moves_safe` | AI_Manager Step | Primary move generation |
| `ai_pick_safe_move` | AI_Manager Step, ai_handle_stepping_stone_move | Heuristic move selection |
| `ai_execute_move_animated` | AI_Manager Step | Execute AI moves with animation |
| `ai_is_king_in_check_simple` | AI_Manager Step, ai_pick_safe_move | Check detection |
| `ai_handle_stepping_stone_move` | AI_Manager Step | Stepping stone phase handling |
| `ai_end_stepping_stone_sequence` | ai_handle_stepping_stone_move | Cleanup stepping stone state |
| `ai_set_difficulty_simple` | AI_Manager Create | Set difficulty 1-5 |
| `ai_move_escapes_check` | ai_pick_safe_move | Test if move escapes check |
| `ai_move_puts_king_in_check` | ai_pick_safe_move | Test if king move is dangerous |
| `ai_get_piece_value` | ai_pick_safe_move | Material values lookup |
| `easeInOutQuad` | Chess_Piece_Obj Step, Stepping_Stone_Obj | Animation easing |

### ⚠️ KEEP FOR NOW - Support Functions (Called by the above)

| Script | Called By | Notes |
|--------|-----------|-------|
| `ai_evaluate_king_safety_safe` | ai_evaluate_board | Indirect, but ai_evaluate_board itself unused |
| `ai_evaluate_pawn_structure_safe` | ai_evaluate_board | Same |
| `ai_evaluate_center_control_safe` | ai_evaluate_board | Same |

### 🗑️ DELETE - Duplicate/Redundant Move Generation

These all do the same thing in slightly different ways. Keep only `ai_get_legal_moves_safe`.

```
ai_get_legal_moves            # Older version, uses ai_generate_moves
ai_get_legal_moves_fast       # Another version with inline move gen
ai_generate_moves             # Only called by ai_get_legal_moves
ai_generate_piece_moves       # Unused
ai_is_legal_move              # Only called by ai_get_legal_moves
ai_is_move_safe               # Only called by ai_get_legal_moves_fast (unused)
ai_is_safe_move               # Duplicate name, same function
```

### 🗑️ DELETE - Unused Minimax System

The full minimax system exists but is NEVER called from the Step event.

```
ai_minimax                    # Never called from core
ai_minimax_optimized          # Never called from core
ai_minimax_window             # Never called from core
ai_find_best_move             # Would call minimax, but not used
ai_iterative_deepening_search # Never called
ai_search_depth               # Never called
ai_search_depth_with_window   # Never called
ai_quiescence_search          # Only called by minimax (unused)
ai_quiescence_search_optimized# Only called by minimax_optimized (unused)
ai_fast_tactical_search       # Never called
```

### 🗑️ DELETE - Unused State Management

```
ai_save_game_state            # For simulation, but minimax unused
ai_restore_game_state         # For simulation, but minimax unused
ai_make_move_simulation       # For simulation, but minimax unused
ai_copy_game_state            # Never called
```

### 🗑️ DELETE - Unused Transposition/Opening Book

```
ai_store_transposition_table  # Never called from core
ai_probe_transposition_table  # Never called from core
ai_probe_transposition_table_move # Never called
ai_clear_transposition_table  # Never called
ai_check_opening_book         # Never called
ai_load_opening_book          # Never called
ai_save_opening_book          # Never called
ai_update_opening_book        # Never called
ai_calculate_position_hash_for_opening # Never called from core
ai_get_board_hash             # Only for unused features
ai_get_current_game_hash      # Only for unused features
```

### 🗑️ DELETE - Unused Move Ordering/History

```
ai_order_moves                # Only called by unused minimax
ai_order_moves_advanced       # Never called
ai_order_captures             # Never called
ai_update_killer_move         # Never called from core
ai_update_history             # Never called from core
ai_score_move_fast            # Never called from core
ai_score_move_tactical        # Never called
ai_get_non_repetitive_moves   # Never called
ai_is_move_repetitive         # Never called
ai_moves_equal                # Only for unused features
ai_detect_infinite_loop       # Never called
check_for_loops               # Never called
```

### 🗑️ DELETE - Unused Difficulty Systems

Keep only `ai_set_difficulty_simple`. Delete:

```
ai_set_difficulty             # Not called
ai_set_difficulty_enhanced    # Not called from core
ai_set_difficulty_fast        # Not called
ai_adaptive_difficulty_update # Not called
ai_increase_difficulty        # Not called
ai_decrease_difficulty        # Not called
ai_demonstrate_difficulty     # Debug only
ai_get_current_difficulty     # Not called from core
```

### 🗑️ DELETE - Unused Evaluation Functions

Keep piece-square tables in AI_Manager Create. Delete:

```
ai_evaluate_board             # Never called from Step (minimax-only)
ai_evaluate_board_enhanced    # Never called
ai_evaluate_move_quality      # Never called
ai_evaluate_stepping_stones   # Never called
ai_evaluate_bridge_control    # Never called
ai_evaluate_water_control     # Never called
ai_evaluate_conveyor_belt_positioning # Never called
ai_evaluate_center_control    # Not the _safe version
ai_evaluate_king_safety       # Not the _safe version
ai_evaluate_king_safety_enhanced # Never called
ai_evaluate_pawn_structure    # Not the _safe version
ai_evaluate_endgame_factors   # Never called
ai_evaluate_passed_pawns_endgame # Never called
ai_is_passed_pawn             # Never called
ai_get_positional_bonus       # Never called
ai_get_rank                   # Never called
ai_get_square_index           # Minimal use
```

### 🗑️ DELETE - Unused Tactical Analysis

```
ai_move_creates_fork          # Never called
ai_move_creates_pin           # Never called
ai_move_creates_skewer        # Never called
ai_move_creates_threat        # Never called
ai_move_blocks_threat         # Never called
ai_move_defends_piece         # Never called
ai_move_improves_position     # Never called
ai_move_gives_check_fast      # Never called
```

### 🗑️ DELETE - Unused Check/Checkmate

```
ai_is_checkmate               # Only called by unused minimax
ai_is_stalemate               # Only called by unused minimax
ai_is_king_in_check           # Older version, using simple one now
ai_is_square_attacked         # Never called
```

### 🗑️ DELETE - Emergency/Fix Scripts

These are band-aids for broken code. After cleanup, they won't be needed:

```
ai_emergency_fix              # Patches broken state
ai_emergency_fix_all          # Patches broken state
ai_emergency_move             # Fallback random move
ai_emergency_reset            # Reset state
ai_emergency_stop             # Stop AI
ai_fix_common_issues          # Band-aid
ai_fix_stuck_pieces           # Band-aid
ai_reset_to_basic_mode        # Reset
ai_switch_to_simple_mode      # Already in simple mode
ai_initialize_clean           # Redundant with Create
ai_restart_clean              # Redundant
```

### 🗑️ DELETE - Test/Debug Scripts

```
ai_test_basic_functions       # Debug
ai_test_move_generation       # Debug
ai_test_simple_move           # Debug
ai_quick_test                 # Debug
ai_stress_test                # Debug
ai_performance_test           # Debug
ai_performance_benchmark      # Debug
ai_verify_installation        # Debug
ai_debug_current_position     # Debug
ai_debug_status               # Debug
ai_debug_stepping_stone_state # Debug
ai_comprehensive_debug        # Debug
ai_show_stepping_stone_help   # Debug
debug_stepping_stones         # Debug
debug_stepping_stone_status   # Debug
```

### 🗑️ DELETE - Unused Move Execution Variants

Keep only `ai_execute_move_animated`. Delete:

```
ai_execute_move               # Older version
ai_execute_move_fast          # Older version
ai_execute_move_fast_robust   # Older version
ai_execute_move_simple        # Older version
ai_execute_normal_move        # Older version
ai_execute_castling_move      # Separate, but unused
ai_execute_en_passant_move    # Separate, but unused
ai_make_move                  # Simulation, unused
```

### 🗑️ DELETE - Unused Stepping Stone Variants

Keep core stepping stone functions. Delete:

```
ai_force_stepping_stone_move  # Debug/test
ai_force_stepping_stone_phase2 # Debug/test
ai_manual_stepping_stone_advance # Debug
ai_sync_stepping_stone_state  # Unused
force_ai_stepping_stone_test  # Test
test_stepping_stone_complete  # Test
test_stepping_stone_simple    # Test
```

### 🗑️ DELETE - Miscellaneous Unused

```
ai_calculate_time_budget      # Never called
ai_should_use_fast_mode       # Never called
ai_toggle_enabled             # Keyboard handler only
ai_update_piece_valid_moves   # Never called from core
ai_validate_move_legality     # Never called
ai_find_piece_at_position     # Minimal use
ai_convert_move_to_string     # Debug only
ai_convert_string_to_move     # Never called
ai_analyze_position_complexity # Never called
ai_count_moves_played         # Never called
ai_get_performance_stats      # Never called
ai_reset_performance_stats    # Never called
ai_update_performance_metrics # Never called
ai_step_event_robust          # Not used as step
ai_step_event_simple          # Not used as step
ai_pick_best_move_fast        # Not called
ai_simple_fallback_move       # Not called
ai_safe_test_move             # Not called
ai_force_move                 # Debug
ai_force_move_now             # Debug
force_ai_move_now             # Debug
quick_difficulty_test         # Debug
quick_start_ai                # Debug
restore_normal_moves          # Debug
simulate_ai_turn              # Test
test_ai_system                # Test
verify_keyboard_controls      # Test
array_sum_custom              # Utility, may be unused
```

## Implementation Plan

### Phase 1: Backup
1. Create Git branch: `ai-cleanup`
2. Commit current state with message: "PRE-CLEANUP: Backup of bloated AI"

### Phase 2: Safe Deletions
Delete scripts in this order (least risky first):
1. Test/debug scripts (definitely unused)
2. Emergency/fix scripts (band-aids)
3. Duplicate move execution variants
4. Unused tactical analysis
5. Unused evaluation functions
6. Unused move ordering/history
7. Transposition/opening book
8. State management (save/restore)
9. Minimax system
10. Duplicate difficulty systems
11. Duplicate move generation

After each batch:
- Run game
- Test player movement
- Test AI movement
- Test stepping stone (both player and AI)

### Phase 3: Consolidate
1. Ensure all kept functions work correctly
2. Remove any remaining dead code in kept functions
3. Add proper documentation

### Final Script Count Target: ~15-20 scripts

## Scripts to Keep (Final List)

```gml
// Core AI
ai_get_legal_moves_safe       // Move generation
ai_pick_safe_move             // Move selection
ai_execute_move_animated      // Move execution
ai_is_king_in_check_simple    // Check detection
ai_move_escapes_check         // Check escape test
ai_move_puts_king_in_check    // King safety test
ai_get_piece_value            // Material values

// Stepping Stone Support
ai_handle_stepping_stone_move // Phase handler
ai_end_stepping_stone_sequence // Cleanup

// Difficulty
ai_set_difficulty_simple      // Simple 1-5

// Utilities
easeInOutQuad                 // Animation (non-ai script)
```

Total: 10 AI scripts + utility functions in AI_Manager

## Risk Assessment
- **Low risk**: Test/debug script removal
- **Medium risk**: Duplicate function removal (may miss a call)
- **High risk**: None, since we're keeping all actually-used functions

## Verification
After cleanup, verify:
1. ✓ Player can move pieces
2. ✓ AI makes moves on its turn
3. ✓ Captures work (player and AI)
4. ✓ Check detection works
5. ✓ Stepping stones work for player
6. ✓ Stepping stones work for AI
7. ✓ Difficulty setting works
8. ✓ No GML errors in output

## Success Criteria
- AI scripts reduced from 150 to ~15
- No functionality lost
- Game plays identically
- Codebase easier to understand and maintain
