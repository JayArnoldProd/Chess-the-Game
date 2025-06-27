/// @function ai_search_depth(depth)
/// @param {real} depth The depth to search
/// @returns {struct} The best move found at this depth

function ai_search_depth(depth) {
    var legal_moves = ai_get_legal_moves(1); // Get moves for black (AI)
    
    if (array_length(legal_moves) == 0) {
        return undefined; // No legal moves
    }
    
    // Order moves for better alpha-beta pruning
    legal_moves = ai_order_moves_advanced(legal_moves);
    
    var best_move = undefined;
    var best_score = -999999;
    var alpha = -999999;
    var beta = 999999;
    
    // Try each legal move
    for (var i = 0; i < array_length(legal_moves) && !search_cancelled; i++) {
        var move = legal_moves[i];
        var game_state = ai_save_game_state();
        
        ai_make_move_simulation(move);
        nodes_searched++;
        
        // Search with null window first for speed (except first move)
        var score_;
        if (i == 0) {
            score_ = ai_minimax_optimized(depth - 1, alpha, beta, false, 0);
        } else {
            // Null window search
            score_ = ai_minimax_optimized(depth - 1, alpha, alpha + 1, false, 0);
            if (score_ > alpha && score_ < beta) {
                // Re-search with full window
                score_ = ai_minimax_optimized(depth - 1, alpha, beta, false, 0);
            }
        }
        
        ai_restore_game_state(game_state);
        
        if (search_cancelled) break;
        
        if (score_ > best_score) {
            best_score = score_;
            best_move = move;
        }
        
        alpha = max(alpha, score_);
        if (beta <= alpha) {
            // Update killer move
            if (!move.is_capture) {
                ai_update_killer_move(move, 0);
            }
            break; // Alpha-beta cutoff
        }
        
        // Check time limit every few moves
        if (i % 10 == 0 && current_time - think_start_time > max_think_time) {
            search_cancelled = true;
            break;
        }
    }
    
    return best_move;
}