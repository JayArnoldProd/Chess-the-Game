/// @function ai_find_best_move(depth__)
/// @param {real} depth__ Maximum search depth__
/// @returns {struct} The best move found

function ai_find_best_move(depth_) {
    var legal_moves = ai_get_legal_moves(1); // Get moves for black (AI)
    
    if (array_length(legal_moves) == 0) {
        return undefined; // No legal moves
    }
    
    var best_move = undefined;
    var best_score = -999999;
    var alpha = -999999;
    var beta = 999999;
    
    // Try each legal move
    for (var i = 0; i < array_length(legal_moves); i++) {
        var move = legal_moves[i];
        var game_state = ai_save_game_state();
        
        ai_make_move_simulation(move);
        
        // Search deeper with minimax
        var score_ = ai_minimax(depth_ - 1, alpha, beta, false);
        
        ai_restore_game_state(game_state);
        
        if (score_ > best_score) {
            best_score = score_;
            best_move = move;
        }
        
        alpha = max(alpha, score_);
        if (beta <= alpha) {
            break; // Alpha-beta pruning
        }
    }
    
    return best_move;
}