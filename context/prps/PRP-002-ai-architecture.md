# PRP-002: AI Architecture Redesign

## Overview
After cleanup (PRP-001), redesign the AI with a clean minimax + alpha-beta system that properly handles stepping stones and other world gimmicks.

## Current Architecture (Post-Cleanup)

```
AI_Manager Step
├── Check if AI turn (turn == 1)
├── Handle stepping stone sequence if active
├── Wait for animations
├── Get legal moves: ai_get_legal_moves_safe(1)
├── Pick best move: ai_pick_safe_move(moves)
└── Execute: ai_execute_move_animated(move)
```

**Problem**: `ai_pick_safe_move` uses only simple heuristics:
- Capture value
- Center bonus
- Development bonus
- Stepping stone bonus
- Random factor

No actual search depth, no lookahead, just single-ply evaluation.

## Target Architecture

```
AI_Manager Step
├── Check if AI turn
├── Handle stepping stone sequence (unchanged)
├── Wait for animations (unchanged)
├── Get legal moves: ai_get_legal_moves(1)
├── Search: ai_search(moves, depth)
│   ├── For each move:
│   │   ├── Make move (simulation)
│   │   ├── Handle stepping stone if applicable
│   │   ├── Recurse or evaluate
│   │   └── Unmake move
│   └── Return best move + score
└── Execute: ai_execute_move_animated(best_move)
```

## Key Design Decisions

### 1. Simulation System
We need to simulate moves WITHOUT actually moving GameMaker instances.

**Approach A: Virtual Board** ✅ Recommended
```gml
// Create a lightweight board representation
board = array_create(8, undefined);
for (var i = 0; i < 8; i++) {
    board[i] = array_create(8, noone);
}

// Populate from actual pieces
with (Chess_Piece_Obj) {
    var bx = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var by = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    if (bx >= 0 && bx < 8 && by >= 0 && by < 8) {
        board[by][bx] = {
            piece_id: piece_id,
            piece_type: piece_type,
            has_moved: has_moved,
            instance: id
        };
    }
}
```

**Approach B: Instance Snapshot** (Current broken approach)
The existing `ai_save_game_state`/`ai_restore_game_state` tries to snapshot instance positions, but:
- Fragile with animations
- Interacts badly with stepping stones
- Risk of corrupting game state

### 2. Move Generation for Simulation
Need to generate moves from virtual board state, not just `valid_moves` arrays.

```gml
/// @function ai_generate_moves_from_board(board, color)
/// @param {array} board 8x8 virtual board
/// @param {real} color 0=white, 1=black
function ai_generate_moves_from_board(board, color) {
    var moves = [];
    
    for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
            var piece = board[y][x];
            if (piece == noone || piece.piece_type != color) continue;
            
            var piece_moves = ai_get_piece_moves_virtual(board, x, y, piece);
            for (var i = 0; i < array_length(piece_moves); i++) {
                array_push(moves, piece_moves[i]);
            }
        }
    }
    
    return moves;
}
```

### 3. Stepping Stone Handling in Simulation
This is the tricky part. Stepping stones create two-move sequences.

**When simulating a move to a stepping stone:**
```gml
function ai_simulate_stepping_stone_move(board, move) {
    // Move lands on stepping stone
    // Returns array of possible follow-up board states
    
    var results = [];
    var stone_x = move.to_x;
    var stone_y = move.to_y;
    
    // Phase 1: 8-directional moves from stone position
    for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            
            var p1_x = stone_x + dx;
            var p1_y = stone_y + dy;
            
            // Check if phase 1 target is valid (on board, empty)
            if (!ai_is_valid_tile(p1_x, p1_y)) continue;
            if (board[p1_y][p1_x] != noone) continue;
            
            // Now from p1, generate phase 2 moves (normal piece moves)
            var temp_board = ai_copy_board(board);
            temp_board[move.from_y][move.from_x] = noone;
            temp_board[p1_y][p1_x] = board[move.from_y][move.from_x];
            
            var phase2_moves = ai_get_piece_moves_virtual(
                temp_board, p1_x, p1_y, 
                temp_board[p1_y][p1_x]
            );
            
            for (var i = 0; i < array_length(phase2_moves); i++) {
                var p2 = phase2_moves[i];
                var final_board = ai_copy_board(temp_board);
                
                // Handle capture if any
                var captured = final_board[p2.to_y][p2.to_x];
                final_board[p1_y][p1_x] = noone;
                final_board[p2.to_y][p2.to_x] = temp_board[p1_y][p1_x];
                
                array_push(results, {
                    board: final_board,
                    captured: captured,
                    was_stepping_stone: true,
                    phase1_pos: [p1_x, p1_y],
                    final_pos: [p2.to_x, p2.to_y]
                });
            }
        }
    }
    
    return results;
}
```

### 4. Alpha-Beta Search

```gml
/// @function ai_alphabeta(board, depth, alpha, beta, maximizing, stones)
/// @param {array} board Virtual board state
/// @param {real} depth Remaining depth
/// @param {real} alpha Alpha bound
/// @param {real} beta Beta bound
/// @param {bool} maximizing True for AI (black)
/// @param {array} stones Stepping stone positions
function ai_alphabeta(board, depth, alpha, beta, maximizing, stones) {
    // Terminal conditions
    if (depth == 0) {
        return { score: ai_evaluate_virtual(board), move: undefined };
    }
    
    var color = maximizing ? 1 : 0;
    var moves = ai_generate_moves_from_board(board, color);
    
    if (array_length(moves) == 0) {
        // No moves - checkmate or stalemate
        var in_check = ai_is_king_in_check_virtual(board, color);
        if (in_check) {
            return { score: maximizing ? -99999 : 99999, move: undefined };
        } else {
            return { score: 0, move: undefined }; // Stalemate
        }
    }
    
    // Order moves for better pruning
    moves = ai_order_moves_virtual(moves, board);
    
    var best_move = moves[0];
    
    if (maximizing) {
        var max_eval = -infinity;
        
        for (var i = 0; i < array_length(moves); i++) {
            var move = moves[i];
            
            // Check if move lands on stepping stone
            if (ai_is_stepping_stone(stones, move.to_x, move.to_y)) {
                // Handle stepping stone - generates multiple possible outcomes
                var outcomes = ai_simulate_stepping_stone_move(board, move);
                
                for (var j = 0; j < array_length(outcomes); j++) {
                    var result = ai_alphabeta(
                        outcomes[j].board, depth - 1, 
                        alpha, beta, false, stones
                    );
                    
                    if (result.score > max_eval) {
                        max_eval = result.score;
                        best_move = move;
                        best_move.stepping_outcome = outcomes[j];
                    }
                    
                    alpha = max(alpha, result.score);
                    if (beta <= alpha) break;
                }
            } else {
                // Normal move
                var new_board = ai_make_move_virtual(board, move);
                var result = ai_alphabeta(
                    new_board, depth - 1, alpha, beta, false, stones
                );
                
                if (result.score > max_eval) {
                    max_eval = result.score;
                    best_move = move;
                }
                
                alpha = max(alpha, result.score);
            }
            
            if (beta <= alpha) break; // Prune
        }
        
        return { score: max_eval, move: best_move };
        
    } else {
        var min_eval = infinity;
        
        for (var i = 0; i < array_length(moves); i++) {
            var move = moves[i];
            
            // Similar logic for minimizing player
            if (ai_is_stepping_stone(stones, move.to_x, move.to_y)) {
                var outcomes = ai_simulate_stepping_stone_move(board, move);
                
                for (var j = 0; j < array_length(outcomes); j++) {
                    var result = ai_alphabeta(
                        outcomes[j].board, depth - 1,
                        alpha, beta, true, stones
                    );
                    
                    if (result.score < min_eval) {
                        min_eval = result.score;
                        best_move = move;
                    }
                    
                    beta = min(beta, result.score);
                    if (beta <= alpha) break;
                }
            } else {
                var new_board = ai_make_move_virtual(board, move);
                var result = ai_alphabeta(
                    new_board, depth - 1, alpha, beta, true, stones
                );
                
                if (result.score < min_eval) {
                    min_eval = result.score;
                    best_move = move;
                }
                
                beta = min(beta, result.score);
            }
            
            if (beta <= alpha) break;
        }
        
        return { score: min_eval, move: best_move };
    }
}
```

### 5. Evaluation Function

```gml
/// @function ai_evaluate_virtual(board)
function ai_evaluate_virtual(board) {
    var score = 0;
    
    // Material and positional evaluation
    for (var y = 0; y < 8; y++) {
        for (var x = 0; x < 8; x++) {
            var piece = board[y][x];
            if (piece == noone) continue;
            
            var piece_score = 0;
            
            // Material value
            switch (piece.piece_id) {
                case "pawn":   piece_score = 100; break;
                case "knight": piece_score = 320; break;
                case "bishop": piece_score = 330; break;
                case "rook":   piece_score = 500; break;
                case "queen":  piece_score = 900; break;
                case "king":   piece_score = 20000; break;
            }
            
            // Positional bonus from piece-square tables
            var table_y = (piece.piece_type == 0) ? y : (7 - y);
            piece_score += ai_get_positional_value(piece.piece_id, x, table_y);
            
            // Apply to total (positive for black/AI, negative for white/player)
            if (piece.piece_type == 1) {
                score += piece_score;
            } else {
                score -= piece_score;
            }
        }
    }
    
    return score;
}
```

### 6. Difficulty Levels

```gml
/// @function ai_set_difficulty(level)
function ai_set_difficulty(level) {
    level = clamp(level, 1, 5);
    
    with (AI_Manager) {
        switch (level) {
            case 1: // Beginner
                search_depth = 1;
                use_randomness = true;
                random_factor = 50; // ±50 centipawns noise
                ai_move_delay = 60;
                break;
                
            case 2: // Easy
                search_depth = 2;
                use_randomness = true;
                random_factor = 30;
                ai_move_delay = 45;
                break;
                
            case 3: // Medium
                search_depth = 3;
                use_randomness = true;
                random_factor = 15;
                ai_move_delay = 30;
                break;
                
            case 4: // Hard
                search_depth = 4;
                use_randomness = false;
                random_factor = 0;
                ai_move_delay = 20;
                break;
                
            case 5: // Expert
                search_depth = 5;
                use_randomness = false;
                random_factor = 0;
                ai_move_delay = 15;
                break;
        }
    }
}
```

## New Script List (Post-Redesign)

### Core Search
- `ai_alphabeta(board, depth, alpha, beta, maximizing, stones)` - Main search
- `ai_search(depth)` - Entry point, builds virtual board and calls search

### Virtual Board
- `ai_build_virtual_board()` - Create board array from instances
- `ai_copy_board(board)` - Deep copy board state
- `ai_make_move_virtual(board, move)` - Apply move to virtual board
- `ai_generate_moves_from_board(board, color)` - Generate moves from state
- `ai_get_piece_moves_virtual(board, x, y, piece)` - Single piece move gen
- `ai_is_king_in_check_virtual(board, color)` - Check detection on virtual

### Stepping Stone Support
- `ai_get_stepping_stones()` - Get stone positions array
- `ai_is_stepping_stone(stones, x, y)` - Check if tile has stone
- `ai_simulate_stepping_stone_move(board, move)` - Simulate stone sequence

### Evaluation
- `ai_evaluate_virtual(board)` - Evaluate virtual board state
- `ai_get_positional_value(piece_id, x, y)` - Piece-square lookup

### Move Ordering
- `ai_order_moves_virtual(moves, board)` - Order for alpha-beta efficiency

### Execution (Keep from current)
- `ai_execute_move_animated(move)` - Execute real move
- `ai_handle_stepping_stone_move()` - Handle real stone sequence
- `ai_end_stepping_stone_sequence()` - Cleanup stone state

### Settings
- `ai_set_difficulty(level)` - Configure search depth & behavior

**Total: ~18 scripts** (similar count to post-cleanup, but much more capable)

## Implementation Order

### Phase 1: Virtual Board Foundation
1. `ai_build_virtual_board()`
2. `ai_copy_board(board)`
3. `ai_make_move_virtual(board, move)`

### Phase 2: Move Generation
1. `ai_get_piece_moves_virtual(board, x, y, piece)`
2. `ai_generate_moves_from_board(board, color)`

### Phase 3: Evaluation
1. `ai_evaluate_virtual(board)`
2. `ai_get_positional_value(piece_id, x, y)`
3. `ai_is_king_in_check_virtual(board, color)`

### Phase 4: Basic Search
1. `ai_alphabeta(board, depth, ...)` (without stepping stone)
2. `ai_search(depth)`
3. Integrate with AI_Manager Step

### Phase 5: Stepping Stone Integration
1. `ai_get_stepping_stones()`
2. `ai_is_stepping_stone(stones, x, y)`
3. `ai_simulate_stepping_stone_move(board, move)`
4. Update ai_alphabeta to handle stones

### Phase 6: Polish
1. `ai_order_moves_virtual(moves, board)`
2. `ai_set_difficulty(level)`
3. Testing and tuning

## Testing Plan

1. **Basic moves**: Verify AI makes legal moves at depth 1
2. **Captures**: Verify AI takes free pieces
3. **Check response**: Verify AI escapes check
4. **Stepping stones**: Verify AI uses stones correctly
5. **Depth testing**: Verify deeper search finds better moves
6. **Performance**: Ensure depth 3-4 runs in <1 second

## Success Criteria

- [ ] AI plays legal moves at all difficulty levels
- [ ] AI captures when advantageous
- [ ] AI responds to check correctly
- [ ] AI uses stepping stones effectively
- [ ] Depth 4 search completes in reasonable time
- [ ] Difficulty levels feel distinct
- [ ] No game state corruption after AI moves
