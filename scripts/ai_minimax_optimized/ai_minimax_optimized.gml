/// @function ai_minimax_optimized(depth, alpha, beta, maximizing_player, ply)
/// @param {real} depth Current search depth
/// @param {real} alpha Alpha value for pruning
/// @param {real} beta Beta value for pruning
/// @param {bool} maximizing_player Whether current player is maximizing
/// @param {real} ply Distance from root
/// @returns {real} The evaluation score_

function ai_minimax_optimized(depth, alpha, beta, maximizing_player, ply) {
    nodes_searched++;
    
    // Check time limit periodically
    if (nodes_searched % 1000 == 0 && current_time - think_start_time > max_think_time) {
        search_cancelled = true;
        return 0;
    }
    
    if (search_cancelled) return 0;
    
    // Check transposition table
    var tt_entry = ai_probe_transposition_table(depth);
    if (tt_entry != undefined) {
        search_stats.tt_hits++;
        if (tt_entry.flag == 0) { // Exact score_
            return tt_entry.score_;
        } else if (tt_entry.flag == 1 && tt_entry.score_ >= beta) { // Lower bound
            return beta;
        } else if (tt_entry.flag == 2 && tt_entry.score_ <= alpha) { // Upper bound
            return alpha;
        }
    } else {
        search_stats.tt_misses++;
    }
    
    // Terminal conditions
    if (depth <= 0) {
        var score_ = ai_quiescence_search_optimized(alpha, beta, maximizing_player, 4);
        ai_store_transposition_table(depth, score_, 0, undefined); // Exact
        return score_;
    }
    
    var current_color = maximizing_player ? 1 : 0;
    
    // Check for checkmate/stalemate
    if (ai_is_checkmate(current_color)) {
        var mate_score = maximizing_player ? (-999999 + ply) : (999999 - ply);
        ai_store_transposition_table(depth, mate_score, 0, undefined);
        return mate_score;
    }
    
    if (ai_is_stalemate(current_color)) {
        ai_store_transposition_table(depth, 0, 0, undefined);
        return 0; // Stalemate is a draw
    }
    
    var legal_moves = ai_get_legal_moves(current_color);
    
    if (array_length(legal_moves) == 0) {
        var score_ = ai_evaluate_board();
        ai_store_transposition_table(depth, score_, 0, undefined);
        return score_;
    }
    
    // Order moves for better pruning
    legal_moves = ai_order_moves_advanced(legal_moves, ply);
    
    var best_move = undefined;
    var original_alpha = alpha;
    
    if (maximizing_player) {
        var max_eval = -999999;
        
        for (var i = 0; i < array_length(legal_moves) && !search_cancelled; i++) {
            var move = legal_moves[i];
            var game_state = ai_save_game_state();
            
            ai_make_move_simulation(move);
            
            // Late move reductions
            var reduction = 0;
            if (i >= 4 && depth >= 3 && !move.is_capture && !ai_is_king_in_check(current_color)) {
                reduction = 1;
            }
            
            var eval = ai_minimax_optimized(depth - 1 - reduction, alpha, beta, false, ply + 1);
            
            // Re-search if reduction failed high
            if (reduction > 0 && eval > alpha) {
                eval = ai_minimax_optimized(depth - 1, alpha, beta, false, ply + 1);
            }
            
            ai_restore_game_state(game_state);
            
            if (search_cancelled) break;
            
            if (eval > max_eval) {
                max_eval = eval;
                best_move = move;
            }
            
            alpha = max(alpha, eval);
            
            if (beta <= alpha) {
                search_stats.cutoffs++;
                // Update killer move and history
                if (!move.is_capture) {
                    ai_update_killer_move(move, ply);
                    ai_update_history(move, depth);
                }
                break; // Beta cutoff
            }
        }
        
        // Store in transposition table
        var flag = (max_eval <= original_alpha) ? 2 : ((max_eval >= beta) ? 1 : 0);
        ai_store_transposition_table(depth, max_eval, flag, best_move);
        
        return max_eval;
    } else {
        var min_eval = 999999;
        
        for (var i = 0; i < array_length(legal_moves) && !search_cancelled; i++) {
            var move = legal_moves[i];
            var game_state = ai_save_game_state();
            
            ai_make_move_simulation(move);
            
            // Late move reductions
            var reduction = 0;
            if (i >= 4 && depth >= 3 && !move.is_capture && !ai_is_king_in_check(current_color)) {
                reduction = 1;
            }
            
            var eval = ai_minimax_optimized(depth - 1 - reduction, alpha, beta, true, ply + 1);
            
            // Re-search if reduction failed high
            if (reduction > 0 && eval < beta) {
                eval = ai_minimax_optimized(depth - 1, alpha, beta, true, ply + 1);
            }
            
            ai_restore_game_state(game_state);
            
            if (search_cancelled) break;
            
            if (eval < min_eval) {
                min_eval = eval;
                best_move = move;
            }
            
            beta = min(beta, eval);
            
            if (beta <= alpha) {
                search_stats.cutoffs++;
                // Update killer move and history
                if (!move.is_capture) {
                    ai_update_killer_move(move, ply);
                    ai_update_history(move, depth);
                }
                break; // Alpha cutoff
            }
        }
        
        // Store in transposition table
        var flag = (min_eval >= beta) ? 1 : ((min_eval <= alpha) ? 2 : 0);
        ai_store_transposition_table(depth, min_eval, flag, best_move);
        
        return min_eval;
    }
}