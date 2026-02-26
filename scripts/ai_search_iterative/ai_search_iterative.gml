/// @function ai_search_iterative(time_limit_ms)
/// @description Iterative deepening search with time limit and world awareness
/// @param {real} time_limit_ms Maximum time in milliseconds
/// @returns {struct} Best move found
/// NOTE: Multi-frame search in AI_Manager/Step_0.gml is now the primary method.
/// This function serves as a fallback for single-frame search when needed.
function ai_search_iterative(time_limit_ms = 2000) {
    // No hard cap needed - multi-frame handles long searches gracefully
    
    // Initialize search state
    global.ai_search_start_time = get_timer() / 1000; // Convert to ms
    global.ai_search_time_limit = time_limit_ms;
    global.ai_search_nodes = 0;
    global.ai_search_stop = false;
    global.ai_search_depth_completed = 0;
    
    // Initialize TT if needed
    if (!variable_global_exists("tt_entries")) {
        ai_tt_init(16); // 65536 entries
    }
    
    // Build virtual world (includes board, tiles, and world objects)
    var world_state = ai_build_virtual_world();
    var board = world_state.board;
    var hash = ai_compute_hash(board);
    
    // Store world state in global for nested search functions
    global.ai_current_world_state = world_state;
    
    // Get stepping stones for bonus (legacy - now in world_state.objects)
    var stones = world_state.objects.stepping_stones;
    
    show_debug_message("AI Search: World=" + world_state.world + ", Mechanics=" + string(world_state.mechanics) + ", Time limit: " + string(time_limit_ms) + "ms (capped)");
    
    var best_move = undefined;
    var best_score = -999999;
    
    // Generate root moves (world-aware: filters water/void suicide moves)
    var root_moves = ai_generate_moves_world_aware(board, 1); // AI is black (1)
    
    if (array_length(root_moves) == 0) {
        show_debug_message("AI Search: No legal moves!");
        return undefined;
    }
    
    // If only one legal move, return it immediately
    if (array_length(root_moves) == 1) {
        return ai_convert_virtual_move_to_real(root_moves[0]);
    }
    
    // Order root moves using previous best move from TT
    root_moves = ai_order_root_moves(root_moves, hash);
    
    // Iterative deepening
    var max_depth = 20; // Maximum depth
    
    for (var _depth = 1; _depth <= max_depth; _depth++) {
        // Time check before starting new depth
        if (ai_search_should_stop()) break;
        
        var alpha = -999999;
        var beta = 999999;
        var iteration_best_move = undefined;
        var iteration_best_score = -999999;
        
        // Search each root move
        for (var i = 0; i < array_length(root_moves); i++) {
            var move = root_moves[i];
            
            // Check time
            if (ai_search_should_stop()) {
                break;
            }
            
            // Make move
            var new_board = ai_copy_board(board);
            ai_make_move_virtual(new_board, move);
            var new_hash = ai_update_hash(hash, 
                move.from_row * 8 + move.from_col,
                move.to_row * 8 + move.to_col,
                {piece_id: move.piece_id, piece_type: move.piece_type},
                move.is_capture ? {piece_id: "pawn", piece_type: 0} : noone // Simplified
            );
            
            // Search with negamax (note: minimizing for white's response)
            var _score;
            if (i == 0) {
                // Full window search for first move
                _score = -ai_negamax_ab(new_board, new_hash, _depth - 1, -beta, -alpha, false, stones);
            } else {
                // Null window search (PVS)
                _score = -ai_negamax_ab(new_board, new_hash, _depth - 1, -alpha - 1, -alpha, false, stones);
                if (_score > alpha && _score < beta) {
                    // Re-search with full window
                    _score = -ai_negamax_ab(new_board, new_hash, _depth - 1, -beta, -alpha, false, stones);
                }
            }
            
            // Stepping stone bonus at root (stones are now structs with .col, .row)
            for (var s = 0; s < array_length(stones); s++) {
                if (stones[s].col == move.to_col && stones[s].row == move.to_row) {
                    _score += 30;
                    break;
                }
            }
            
            if (_score > iteration_best_score) {
                iteration_best_score = _score;
                iteration_best_move = move;
            }
            
            if (_score > alpha) {
                alpha = _score;
            }
        }
        
        // Check if we completed this depth
        if (!global.ai_search_stop && iteration_best_move != undefined) {
            best_move = iteration_best_move;
            best_score = iteration_best_score;
            global.ai_search_depth_completed = _depth;
            
            // Reorder root moves - put best move first
            if (iteration_best_move != undefined) {
                var new_order = [iteration_best_move];
                for (var i = 0; i < array_length(root_moves); i++) {
                    if (root_moves[i] != iteration_best_move) {
                        array_push(new_order, root_moves[i]);
                    }
                }
                root_moves = new_order;
            }
            
            show_debug_message("AI: Depth " + string(_depth) + " completed, score: " + string(best_score) + ", nodes: " + string(global.ai_search_nodes));
        }
        
        // Stop if we've used enough time
        if (ai_search_should_stop()) {
            break;
        }
        
        // Stop if we found a mate
        if (abs(best_score) > 90000) {
            break;
        }
    }
    
    var elapsed = (get_timer() / 1000) - global.ai_search_start_time;
    show_debug_message("AI Search: Best move score " + string(best_score) + ", depth " + string(global.ai_search_depth_completed) + ", " + string(global.ai_search_nodes) + " nodes in " + string(floor(elapsed)) + "ms");
    
    if (best_move == undefined) {
        return undefined;
    }
    
    return ai_convert_virtual_move_to_real(best_move);
}

/// @function ai_search_should_stop()
/// @description Checks if search should stop due to time (every 512 nodes for performance)
function ai_search_should_stop() {
    if (global.ai_search_stop) return true;
    
    // Only check timer every 512 nodes to reduce get_timer() overhead
    if ((global.ai_search_nodes & 511) != 0) return false;
    
    var elapsed = (get_timer() / 1000) - global.ai_search_start_time;
    if (elapsed >= global.ai_search_time_limit) {
        global.ai_search_stop = true;
        return true;
    }
    
    return false;
}

/// @function ai_negamax_ab(_board, _hash, _depth, _alpha, _beta, _maximizing, _stones)
/// @description Negamax with alpha-beta pruning, TT, and world effects
function ai_negamax_ab(_board, _hash, _depth, _alpha, _beta, _maximizing, _stones) {
    global.ai_search_nodes++;
    
    // Time check
    if (ai_search_should_stop()) {
        return 0;
    }
    
    var orig_alpha = _alpha;
    var color = _maximizing ? 1 : 0;
    
    // Transposition table probe
    var tt_entry = ai_tt_probe(_hash, _depth, _alpha, _beta);
    if (tt_entry != undefined && tt_entry.score != undefined) {
        return tt_entry.score;
    }
    var tt_move = (tt_entry != undefined) ? tt_entry.move : undefined;
    
    // Generate moves (world-aware: filters unsafe tile moves)
    var moves = ai_generate_moves_world_aware(_board, color);
    
    // Terminal node
    if (array_length(moves) == 0) {
        var in_check = ai_is_king_in_check_virtual(_board, color);
        if (in_check) {
            return -99999 + (20 - _depth); // Checkmate (prefer faster mates)
        }
        return 0; // Stalemate
    }
    
    // Leaf node - evaluate with world bonuses
    if (_depth <= 0) {
        return ai_quiescence(_board, _hash, _alpha, _beta, _maximizing, 4);
    }
    
    // Order moves
    moves = ai_order_moves_fast(moves, _board, tt_move);
    
    var best_score = -999999;
    var best_move = moves[0];
    
    for (var i = 0; i < array_length(moves); i++) {
        var move = moves[i];
        
        // Make move on a copy of the board
        var new_board = ai_copy_board(_board);
        var captured = (move.is_capture && new_board[move.to_row][move.to_col] != noone) 
                       ? new_board[move.to_row][move.to_col] : noone;
        ai_make_move_virtual(new_board, move);
        
        // Apply world effects (conveyors, water damage, etc.) - only at ply boundaries
        // This simulates what happens when the turn changes
        if (variable_global_exists("ai_current_world_state") && array_length(global.ai_current_world_state.mechanics) > 0) {
            ai_apply_board_world_effects(new_board, global.ai_current_world_state);
        }
        
        var new_hash = ai_update_hash(_hash,
            move.from_row * 8 + move.from_col,
            move.to_row * 8 + move.to_col,
            {piece_id: move.piece_id, piece_type: move.piece_type},
            captured
        );
        
        // Late move reduction
        var reduction = 0;
        if (i >= 4 && _depth >= 3 && !move.is_capture) {
            reduction = 1;
        }
        
        var _score = -ai_negamax_ab(new_board, new_hash, _depth - 1 - reduction, -_beta, -_alpha, !_maximizing, _stones);
        
        // Re-search if reduced search found a better move
        if (reduction > 0 && _score > _alpha) {
            _score = -ai_negamax_ab(new_board, new_hash, _depth - 1, -_beta, -_alpha, !_maximizing, _stones);
        }
        
        if (_score > best_score) {
            best_score = _score;
            best_move = move;
        }
        
        _alpha = max(_alpha, _score);
        if (_alpha >= _beta) {
            break; // Beta cutoff
        }
    }
    
    // Store in TT
    var flag = TT_EXACT;
    if (best_score <= orig_alpha) {
        flag = TT_ALPHA;
    } else if (best_score >= _beta) {
        flag = TT_BETA;
    }
    ai_tt_store(_hash, _depth, best_score, flag, best_move);
    
    return best_score;
}

/// @function ai_quiescence(_board, _hash, _alpha, _beta, _maximizing, _depth)
/// @description Quiescence search for captures only with world awareness
function ai_quiescence(_board, _hash, _alpha, _beta, _maximizing, _depth) {
    global.ai_search_nodes++;
    
    var color = _maximizing ? 1 : 0;
    
    // Stand-pat score with world bonuses
    var stand_pat = ai_evaluate_advanced(_board);
    
    // Add world-specific evaluation bonuses
    if (variable_global_exists("ai_current_world_state")) {
        var _world_bonus = ai_evaluate_world_bonuses(global.ai_current_world_state, 1); // AI is color 1
        stand_pat += _world_bonus;
    }
    
    if (!_maximizing) stand_pat = -stand_pat;
    
    if (stand_pat >= _beta) {
        return _beta;
    }
    
    if (_alpha < stand_pat) {
        _alpha = stand_pat;
    }
    
    if (_depth <= 0) {
        return stand_pat;
    }
    
    // Generate only captures
    var moves = ai_generate_captures_only(_board, color);
    
    for (var i = 0; i < array_length(moves); i++) {
        var move = moves[i];
        
        // Delta pruning - skip if capture can't possibly raise alpha
        var captured_value = ai_get_piece_value_fast(move.captured_piece_id);
        if (stand_pat + captured_value + 200 < _alpha) {
            continue;
        }
        
        // Make move
        var new_board = ai_copy_board(_board);
        ai_make_move_virtual(new_board, move);
        
        var _score = -ai_quiescence(new_board, _hash, -_beta, -_alpha, !_maximizing, _depth - 1);
        
        if (_score >= _beta) {
            return _beta;
        }
        
        if (_score > _alpha) {
            _alpha = _score;
        }
    }
    
    return _alpha;
}

/// @function ai_generate_captures_only(_board, _color)
/// @description Generates only capture moves for quiescence
function ai_generate_captures_only(_board, _color) {
    var captures = [];
    var all_moves = ai_generate_moves_from_board(_board, _color);
    
    for (var i = 0; i < array_length(all_moves); i++) {
        if (all_moves[i].is_capture) {
            // Store captured piece type for MVV-LVA ordering
            var cap_piece = _board[all_moves[i].to_row][all_moves[i].to_col];
            all_moves[i].captured_piece_id = (cap_piece != noone) ? cap_piece.piece_id : "pawn";
            array_push(captures, all_moves[i]);
        }
    }
    
    // Order by MVV-LVA (Most Valuable Victim - Least Valuable Attacker)
    for (var i = 0; i < array_length(captures) - 1; i++) {
        for (var j = i + 1; j < array_length(captures); j++) {
            var score_i = ai_get_piece_value_fast(captures[i].captured_piece_id) - ai_get_piece_value_fast(captures[i].piece_id) / 10;
            var score_j = ai_get_piece_value_fast(captures[j].captured_piece_id) - ai_get_piece_value_fast(captures[j].piece_id) / 10;
            if (score_j > score_i) {
                var temp = captures[i];
                captures[i] = captures[j];
                captures[j] = temp;
            }
        }
    }
    
    return captures;
}

/// @function ai_get_piece_value_fast(piece_id)
/// @description Fast piece value lookup
function ai_get_piece_value_fast(piece_id) {
    switch (piece_id) {
        case "pawn": return 100;
        case "knight": return 320;
        case "bishop": return 330;
        case "rook": return 500;
        case "queen": return 900;
        case "king": return 20000;
        default: return 100;
    }
}

/// @function ai_order_moves_fast(_moves, _board, _tt_move)
/// @description Fast move ordering for better pruning
function ai_order_moves_fast(_moves, _board, _tt_move) {
    var num_moves = array_length(_moves);
    
    // Score each move
    for (var i = 0; i < num_moves; i++) {
        var move = _moves[i];
        var _score = 0;
        
        // TT move gets highest priority
        if (_tt_move != undefined && 
            move.from_col == _tt_move.from_col && move.from_row == _tt_move.from_row &&
            move.to_col == _tt_move.to_col && move.to_row == _tt_move.to_row) {
            _score = 100000;
        }
        // Captures scored by MVV-LVA
        else if (move.is_capture) {
            var victim = (_board != undefined) ? _board[move.to_row][move.to_col] : noone;
            var victim_val = (victim != noone) ? ai_get_piece_value_fast(victim.piece_id) : 100;
            var attacker_val = ai_get_piece_value_fast(move.piece_id);
            _score = 10000 + victim_val * 10 - attacker_val;
        }
        // Pawn pushes
        else if (move.piece_id == "pawn") {
            _score = 500;
        }
        // Piece development
        else if ((move.piece_id == "knight" || move.piece_id == "bishop") &&
                 (move.from_row == 0 || move.from_row == 7)) {
            _score = 400;
        }
        // Center control
        else {
            var center_dist = abs(move.to_col - 3.5) + abs(move.to_row - 3.5);
            _score = 100 - center_dist * 10;
        }
        
        move.sort_score = _score;
    }
    
    // Simple insertion sort (fast for small arrays with mostly sorted data)
    for (var i = 1; i < num_moves; i++) {
        var key = _moves[i];
        var j = i - 1;
        while (j >= 0 && _moves[j].sort_score < key.sort_score) {
            _moves[j + 1] = _moves[j];
            j--;
        }
        _moves[j + 1] = key;
    }
    
    return _moves;
}

/// @function ai_order_root_moves(_moves, _hash)
/// @description Orders root moves using TT hint
function ai_order_root_moves(_moves, _hash) {
    var tt_entry = ai_tt_probe(_hash, 0, -999999, 999999);
    var tt_move = (tt_entry != undefined) ? tt_entry.move : undefined;
    return ai_order_moves_fast(_moves, undefined, tt_move);
}
