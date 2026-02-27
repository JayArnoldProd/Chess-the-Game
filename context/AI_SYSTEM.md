# Chess-the-Game — AI System Documentation

**Last Updated:** 2026-02-27

---

## Overview

The AI system uses iterative deepening alpha-beta search with a multi-frame architecture to prevent game freezes. It supports 5 difficulty levels ranging from instant heuristic moves to 30-second grandmaster-level search.

---

## Virtual Board Representation

The AI never manipulates real game objects during search. Instead, it builds a virtual representation:

### Board Structure

```gml
// 8x8 array of piece structs (or noone)
var board = [
    [piece, piece, piece, piece, piece, piece, piece, piece],  // Row 0 (rank 8)
    [piece, piece, piece, piece, piece, piece, piece, piece],  // Row 1 (rank 7)
    // ...
    [piece, piece, piece, piece, piece, piece, piece, piece]   // Row 7 (rank 1)
];

// Piece struct
var piece = {
    piece_id: "queen",      // pawn, knight, bishop, rook, queen, king
    piece_type: 1,          // 0=white, 1=black
    has_moved: true,        // For castling/pawn double move
    health: 1,              // For HP-based mechanics (future)
    stepping_chain: 0,      // Stepping stone state
    instance: real_obj_id   // Reference to real object
};
```

### World State Structure

```gml
var world_state = {
    world: "pirate_seas",
    mechanics: ["water", "bridges"],
    board: board[8][8],              // Piece positions
    tiles: tiles[8][8],              // Tile types (0, 1, -1)
    objects: {
        stepping_stones: [{col, row, instance}],
        bridges: [{col, row}],
        conveyors: [{start_col, row, length, direction}]
    },
    turn_count: 0
};
```

### Building Virtual World (`ai_build_virtual_world`)

```gml
function ai_build_virtual_world() {
    // Initialize empty board
    var _board = array_create(8);
    for (var row = 0; row < 8; row++) {
        _board[row] = array_create(8, noone);
    }
    
    // Populate from real pieces
    with (Chess_Piece_Obj) {
        var bx = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        var by = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        if (bx >= 0 && bx < 8 && by >= 0 && by < 8) {
            _board[by][bx] = {
                piece_id: piece_id,
                piece_type: piece_type,
                has_moved: has_moved,
                // ...
            };
        }
    }
    
    // Populate tiles, stepping stones, bridges, conveyors...
    
    return { world, mechanics, board, tiles, objects };
}
```

---

## Multi-Frame State Machine

### States

```
┌─────────────────────────────────────────────────────────────────┐
│  IDLE → PREPARING → SEARCHING → EXECUTING → WAITING_TURN_SWITCH │
└─────────────────────────────────────────────────────────────────┘
```

| State | Purpose | Exit Condition |
|-------|---------|----------------|
| `idle` | Wait for AI turn, animations, belt animations | `turn == 1` AND no animations |
| `preparing` | Build virtual world, generate root moves | Moves generated (or checkmate/stalemate) |
| `searching` | Process moves within frame budget | Time limit reached OR all moves evaluated |
| `executing` | Execute best move found | Move started |
| `waiting_turn_switch` | Wait for turn to actually flip | `turn == 0` |

### Frame Budget

The AI searches within a **14ms frame budget** per frame, leaving 6ms for the game loop (60fps = 16.67ms/frame).

```gml
// AI_Manager/Step_0.gml - SEARCHING state
var frame_start = get_timer();
var frame_budget_us = ai_search_frame_budget * 1000;  // 14ms → 14000µs

while ((get_timer() - frame_start) < frame_budget_us) {
    // Search one root move
    var move = ai_search_moves[ai_search_index];
    var score = -ai_negamax_ab(new_board, ...);
    
    if (score > ai_search_best_score) {
        ai_search_best_score = score;
        ai_search_best_move = move;
    }
    
    ai_search_index++;
    if (ai_search_index >= array_length(ai_search_moves)) {
        // Depth complete, start next depth
        ai_search_current_depth++;
        ai_search_index = 0;
    }
}
// Frame budget exhausted — yield to game loop
```

### Why Multi-Frame?

Without multi-frame search, long AI thinking (10-30 seconds at max difficulty) would freeze:
- Cursor movement
- Piece animations
- Conveyor belt animations
- UI updates

With multi-frame, the game remains fully responsive during AI thinking.

---

## Alpha-Beta Search with Iterative Deepening

### Iterative Deepening

Search depth increases gradually until time runs out:

```gml
for (var depth = 1; depth <= max_depth; depth++) {
    // Search all root moves at this depth
    for (var i = 0; i < array_length(root_moves); i++) {
        var score = -ai_negamax_ab(new_board, depth - 1, -beta, -alpha, ...);
        // Track best move...
    }
    
    // Save completed depth results
    ai_completed_best_move = ai_search_best_move;
    ai_completed_depth = depth;
    
    // Reorder moves — best move first for next iteration
    root_moves = [best_move] + other_moves;
    
    if (time_limit_reached) break;
}
```

### Benefits
- **Anytime algorithm:** Always has a valid move, even if interrupted
- **Better move ordering:** Previous iteration's best move searched first
- **Time control:** Can stop cleanly between depths

### Negamax with Alpha-Beta

```gml
function ai_negamax_ab(_board, _hash, _depth, _alpha, _beta, _maximizing, _stones) {
    global.ai_search_nodes++;
    
    // Time check
    if (ai_search_should_stop()) return 0;
    
    // Transposition table probe
    var tt_entry = ai_tt_probe(_hash, _depth, _alpha, _beta);
    if (tt_entry != undefined && tt_entry.score != undefined) {
        return tt_entry.score;
    }
    
    // Generate moves (world-aware)
    var moves = ai_generate_moves_world_aware(_board, color);
    
    // Terminal node (checkmate/stalemate)
    if (array_length(moves) == 0) {
        var in_check = ai_is_king_in_check_virtual(_board, color);
        return in_check ? (-99999 + depth) : 0;  // Checkmate or stalemate
    }
    
    // Leaf node — quiescence search
    if (_depth <= 0) {
        return ai_quiescence(_board, _hash, _alpha, _beta, ...);
    }
    
    // Order moves (TT move first, then captures by MVV-LVA)
    moves = ai_order_moves_fast(moves, _board, tt_move);
    
    var best_score = -999999;
    for (var i = 0; i < array_length(moves); i++) {
        var move = moves[i];
        var new_board = ai_copy_board(_board);
        ai_make_move_virtual(new_board, move);
        
        // Apply world effects (conveyors, water, void)
        ai_apply_board_world_effects(new_board, world_state);
        
        // Late Move Reduction
        var reduction = (i >= 4 && _depth >= 3 && !move.is_capture) ? 1 : 0;
        
        var score = -ai_negamax_ab(new_board, _depth - 1 - reduction, -_beta, -_alpha, ...);
        
        // Re-search if reduction found better move
        if (reduction > 0 && score > _alpha) {
            score = -ai_negamax_ab(new_board, _depth - 1, -_beta, -_alpha, ...);
        }
        
        if (score > best_score) {
            best_score = score;
            best_move = move;
        }
        
        _alpha = max(_alpha, score);
        if (_alpha >= _beta) break;  // Beta cutoff
    }
    
    // Store in transposition table
    ai_tt_store(_hash, _depth, best_score, flag, best_move);
    
    return best_score;
}
```

---

## Evaluation Function

### Components

The evaluation function (`ai_evaluate_advanced`) considers:

1. **Material:** Piece values with middlegame/endgame tapering
2. **Piece-Square Tables:** Position bonuses
3. **Pawn Structure:** Doubled, isolated, passed pawns
4. **King Safety:** Pawn shield, open files near king
5. **Mobility:** Knight and bishop mobility
6. **World Bonuses:** Stepping stones, conveyors, bridges, etc.

### Material Values

| Piece | Middlegame | Endgame |
|-------|------------|---------|
| Pawn | 82 | 94 |
| Knight | 337 | 281 |
| Bishop | 365 | 297 |
| Rook | 477 | 512 |
| Queen | 1025 | 936 |
| King | — | — |

### Piece-Square Tables

Each piece type has a 64-element array of positional bonuses:

```gml
// Pawn PST (from white's perspective)
global.pst_pawn = [
    0,   0,   0,   0,   0,   0,   0,   0,   // Rank 8 (promotion)
    98, 134,  61,  95,  68, 126,  34, -11,  // Rank 7 (advanced)
    // ... more rows
];

// Usage
var pst_bonus = pst_pawn[row * 8 + col];
score_mg += sign * (val_pawn_mg + pst_bonus);
```

### Game Phase

The evaluation interpolates between middlegame and endgame scores based on remaining material:

```gml
// Phase calculation (24 = opening, 0 = endgame)
phase += phase_knight;  // +1 per knight
phase += phase_bishop;  // +1 per bishop
phase += phase_rook;    // +2 per rook
phase += phase_queen;   // +4 per queen

// Interpolation
phase = min(phase, 24);
var mg_weight = phase;
var eg_weight = 24 - phase;
return (score_mg * mg_weight + score_eg * eg_weight) / 24;
```

### Pawn Structure

```gml
function ai_evaluate_pawns(white_pawns, black_pawns) {
    // Doubled pawns penalty
    for (var f = 0; f < 8; f++) {
        if (pawns_on_file[f] > 1) {
            score_mg += 10 * (pawns_on_file[f] - 1);
        }
    }
    
    // Isolated pawns penalty
    if (has_no_adjacent_pawns) {
        score_mg += 20;
    }
    
    // Passed pawns bonus
    if (no_enemy_can_block) {
        score += (7 - rank) * 10;  // More advanced = bigger bonus
    }
}
```

---

## World-Aware Move Generation

### Safe Tile Check

```gml
function ai_is_tile_safe(_world_state, _col, _row, _color) {
    // Off board
    if (_row < 0 || _row >= 8 || _col < 0 || _col >= 8) return false;
    
    var tile_type = _world_state.tiles[_row][_col];
    
    // Void = never safe
    if (tile_type == -1) return false;
    
    // Water = needs bridge
    if (tile_type == 1) {
        for (var b = 0; b < array_length(bridges); b++) {
            if (bridges[b].col == _col && bridges[b].row == _row) {
                return true;
            }
        }
        return false;
    }
    
    return true;
}
```

### World-Aware Move Generation

```gml
function ai_generate_moves_world_aware(_board, _color) {
    var base_moves = ai_generate_moves_from_board(_board, _color);
    var safe_moves = [];
    
    for (var i = 0; i < array_length(base_moves); i++) {
        var move = base_moves[i];
        if (ai_is_tile_safe(world_state, move.to_col, move.to_row, _color)) {
            array_push(safe_moves, move);
        }
    }
    
    return safe_moves;
}
```

### Sliding Pieces and Water

Virtual sliding moves also check tile types:

```gml
// ai_get_piece_moves_virtual.gml
function ai_get_sliding_moves_virtual(_board, _tiles, col, row, piece, directions) {
    var moves = [];
    
    for each direction {
        for (var dist = 1; dist <= 7; dist++) {
            var nc = col + dx * dist;
            var nr = row + dy * dist;
            
            // Off board
            if (nc < 0 || nc >= 8 || nr < 0 || nr >= 8) break;
            
            // Water/void blocks sliding
            var tile_type = _tiles[nr][nc];
            if (tile_type == 1 || tile_type == -1) {
                // Check for bridge on water
                if (tile_type == 1 && has_bridge(nc, nr)) {
                    // Can continue through bridged water
                } else {
                    break;  // Blocked
                }
            }
            
            // Add move
            array_push(moves, {to_col: nc, to_row: nr, ...});
            
            // Blocked by piece
            if (_board[nr][nc] != noone) break;
        }
    }
    
    return moves;
}
```

---

## World Effects Application

After each virtual move in the search tree, world effects are applied:

### Conveyor Belts

```gml
function ai_apply_conveyor_to_board(_board, _conveyors, _tiles) {
    for each conveyor {
        var dir = belt.direction;  // 1=right, -1=left
        
        if (dir > 0) {
            // Process right-to-left to avoid overwriting
            for (var col = end; col >= start; col--) {
                var piece = _board[row][col];
                if (piece != noone) {
                    var new_col = col + 1;
                    _board[row][col] = noone;
                    
                    if (new_col >= 0 && new_col < 8) {
                        var dest_tile = _tiles[row][new_col];
                        if (dest_tile != -1) {  // Not void
                            _board[row][new_col] = piece;
                        }
                        // else: destroyed by void
                    }
                    // else: pushed off board
                }
            }
        }
    }
}
```

### Water Drowning

```gml
function ai_apply_water_to_board(_board, _tiles, _bridges) {
    for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 8; col++) {
            if (_tiles[row][col] == 1 && _board[row][col] != noone) {
                if (!has_bridge_at(col, row)) {
                    _board[row][col] = noone;  // Drowns
                }
            }
        }
    }
}
```

---

## World Evaluation Bonuses

### Stepping Stone Bonus

```gml
function ai_eval_stepping_stone_bonus(_world_state, _color) {
    var score = 0;
    
    for each stepping_stone {
        // Check pieces on and adjacent to stone
        for (var dy = -1; dy <= 1; dy++) {
            for (var dx = -1; dx <= 1; dx++) {
                var piece = _board[stone.row + dy][stone.col + dx];
                if (piece != noone) {
                    var sign = (piece.piece_type == _color) ? 1 : -1;
                    if (dx == 0 && dy == 0) {
                        score += sign * 50;  // On stone = big bonus
                    } else {
                        score += sign * 10;  // Adjacent = small bonus
                    }
                }
            }
        }
    }
    
    return score;
}
```

### Conveyor Position Penalty

```gml
function ai_eval_conveyor_position_bonus(_world_state, _color) {
    var score = 0;
    
    for each piece on conveyor {
        var sign = (piece.piece_type == _color) ? 1 : -1;
        
        // Calculate turns until pushed off
        var turns_to_exit = (dir > 0) ? (end - col + 1) : (col - start + 1);
        
        // Check if exit is hazardous
        var exit_col = (dir > 0) ? end + 1 : start - 1;
        var exit_hazard = (exit_col off board) || (_tiles[row][exit_col] == -1);
        
        if (exit_hazard) {
            var danger = piece_value * (1 / turns_to_exit);  // Closer = more dangerous
            score -= sign * danger;
        }
        
        // General instability penalty
        score -= sign * 15;
    }
    
    return score;
}
```

---

## Difficulty Levels

### Configuration

```gml
function ai_set_difficulty_simple(level) {
    global.ai_difficulty_level = level;
    
    switch (level) {
        case 1:  // Beginner
            AI_Manager.ai_time_limit = 0;      // Instant (heuristic only)
            break;
        case 2:  // Easy
            AI_Manager.ai_time_limit = 500;    // 0.5 seconds
            break;
        case 3:  // Medium
            AI_Manager.ai_time_limit = 2000;   // 2 seconds
            break;
        case 4:  // Hard
            AI_Manager.ai_time_limit = 10000;  // 10 seconds
            break;
        case 5:  // Grandmaster
            AI_Manager.ai_time_limit = 30000;  // 30 seconds
            break;
    }
}
```

### Behavior by Level

| Level | Name | Time | Typical Depth |
|-------|------|------|---------------|
| 1 | Beginner | Instant | 0 (heuristic) |
| 2 | Easy | 500ms | 3-4 |
| 3 | Medium | 2s | 5-6 |
| 4 | Hard | 10s | 7-8 |
| 5 | Grandmaster | 30s | 9-12+ |

---

## Transposition Table

### Zobrist Hashing

Each piece-square combination has a random 64-bit key:

```gml
function ai_zobrist_init() {
    global.zobrist_pieces = [];  // [piece_type][piece_id][square]
    global.zobrist_side = random_get_seed();
    
    for each piece_type {
        for each piece_id {
            for (var sq = 0; sq < 64; sq++) {
                global.zobrist_pieces[type][id][sq] = irandom_range(0, 2147483647);
            }
        }
    }
}

function ai_compute_hash(_board) {
    var hash = 0;
    for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 8; col++) {
            var piece = _board[row][col];
            if (piece != noone) {
                hash ^= global.zobrist_pieces[piece.piece_type][piece.piece_id][row * 8 + col];
            }
        }
    }
    return hash;
}
```

### TT Entry

```gml
var entry = {
    hash: hash,
    depth: depth,
    score: score,
    flag: TT_EXACT | TT_ALPHA | TT_BETA,
    move: best_move
};
```

### TT Probe

```gml
function ai_tt_probe(_hash, _depth, _alpha, _beta) {
    var entry = global.tt_entries[_hash % global.tt_size];
    
    if (entry != undefined && entry.hash == _hash && entry.depth >= _depth) {
        if (entry.flag == TT_EXACT) return entry;
        if (entry.flag == TT_ALPHA && entry.score <= _alpha) return entry;
        if (entry.flag == TT_BETA && entry.score >= _beta) return entry;
    }
    
    // Return entry for move hint even if score unusable
    return entry;
}
```

---

## Quiescence Search

Prevents horizon effect by searching captures until the position is "quiet":

```gml
function ai_quiescence(_board, _hash, _alpha, _beta, _maximizing, _depth) {
    // Stand-pat evaluation
    var stand_pat = ai_evaluate_advanced(_board);
    stand_pat += ai_evaluate_world_bonuses(world_state, 1);
    
    if (stand_pat >= _beta) return _beta;
    if (_alpha < stand_pat) _alpha = stand_pat;
    if (_depth <= 0) return stand_pat;
    
    // Only search captures
    var captures = ai_generate_captures_only(_board, color);
    
    for each capture {
        // Delta pruning — skip if capture can't raise alpha
        var victim_value = ai_get_piece_value(captured);
        if (stand_pat + victim_value + 200 < _alpha) continue;
        
        var new_board = ai_copy_board(_board);
        ai_make_move_virtual(new_board, capture);
        
        var score = -ai_quiescence(new_board, _hash, -_beta, -_alpha, !_maximizing, _depth - 1);
        
        if (score >= _beta) return _beta;
        if (score > _alpha) _alpha = score;
    }
    
    return _alpha;
}
```

---

## Stepping Stone Handling

### Detection

When AI move lands on a stepping stone:

```gml
// ai_execute_move_animated.gml
var on_stone = instance_position(to_x, to_y, Stepping_Stone_Obj);
if (on_stone) {
    // Set up stepping stone state
    piece.stepping_chain = 2;  // Phase 1 pending
    piece.stepping_stone_instance = on_stone;
    piece.stone_original_x = on_stone.x;
    piece.stone_original_y = on_stone.y;
    
    // Tell AI Manager to handle sequence
    AI_Manager.ai_stepping_phase = 1;
    AI_Manager.ai_stepping_piece = piece;
}
```

### Phase Handling

```gml
// ai_handle_stepping_stone_move.gml
if (ai_stepping_phase == 1) {
    // Phase 1: 8-directional move
    var moves = generate_8_directional_moves(piece);
    var best = pick_best_phase1_move(moves);
    
    // Execute move (piece + stone move together)
    piece.move_target_x = best.to_x;
    piece.move_target_y = best.to_y;
    stone.move_target_x = best.to_x;
    stone.move_target_y = best.to_y;
    
    ai_stepping_phase = 2;
}
else if (ai_stepping_phase == 2) {
    // Phase 2: Normal piece move
    var moves = generate_normal_moves(piece);
    var best = ai_pick_safe_move(moves);
    
    // Execute move (stone returns to origin)
    piece.move_target_x = best.to_x;
    piece.move_target_y = best.to_y;
    stone.move_target_x = stone_original_x;
    stone.move_target_y = stone_original_y;
    
    // End sequence
    ai_stepping_phase = 0;
    piece.pending_turn_switch = 0;
}
```

---

## Debug Display

Toggle with F2. Shows:

- Current AI state (colored)
- Turn indicator
- Difficulty and time limit
- Search progress (depth, move index, time, nodes)
- Last search results

```gml
// AI_Manager/Draw_64.gml
if (ai_state == "searching") {
    var elapsed_ms = (get_timer() - ai_search_start_time) / 1000;
    draw_text(x, y, "Thinking... D" + string(depth) + " M" + string(move_index));
    draw_text(x, y + 14, string(elapsed_ms) + "ms | " + string(nodes) + " nodes");
}
```
