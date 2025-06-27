/// @function ai_search_depth_with_window(depth_)
/// @param {real} depth_ Search depth
/// @returns {struct} Best move at this depth
function ai_search_depth_with_window(depth_) {
    var legal_moves = ai_get_legal_moves_fast(1);
    if (array_length(legal_moves) == 0) return undefined;
    
    // Aspiration window search
    var alpha = -search_window;
    var beta = search_window;
    
    // If we have a previous best move, try it first
    if (array_length(best_move_at_depth) > depth_ - 1 && 
        best_move_at_depth[depth_ - 1] != undefined) {
        
        // Move best move to front
        var prev_best = best_move_at_depth[depth_ - 1];
        for (var i = 0; i < array_length(legal_moves); i++) {
            if (ai_moves_equal(legal_moves[i], prev_best)) {
                // Swap to front
                var temp = legal_moves[0];
                legal_moves[0] = legal_moves[i];
                legal_moves[i] = temp;
                break;
            }
        }
    }
    
    var best_move = undefined;
    var best_score = -999999;
    
    for (var i = 0; i < array_length(legal_moves) && !search_cancelled; i++) {
        var move = legal_moves[i];
        var game_state = ai_save_game_state();
        
        ai_make_move_simulation(move);
        var score_ = -ai_minimax_window(depth_ - 1, -beta, -alpha, false);
        ai_restore_game_state(game_state);
        
        if (search_cancelled) break;
        
        if (score_ > best_score) {
            best_score = score_;
            best_move = move;
        }
        
        alpha = max(alpha, score_);
        if (alpha >= beta) break; // Cut-off
        
        // Check time
        if (current_time - think_start_time > time_budget * 0.9) {
            search_cancelled = true;
            break;
        }
    }
    
    return best_move;
}