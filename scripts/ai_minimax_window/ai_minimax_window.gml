/// @function ai_minimax_window(depth_, alpha, beta, maximizing)
/// @returns {real} Position score
function ai_minimax_window(depth_, alpha, beta, maximizing) {
    if (depth_ <= 0 || search_cancelled) {
        return ai_evaluate_board();
    }
    
    var color = maximizing ? 1 : 0;
    var legal_moves = ai_get_legal_moves_fast(color);
    
    if (array_length(legal_moves) == 0) {
        if (ai_is_king_in_check(color)) {
            return maximizing ? -999999 : 999999; // Checkmate
        }
        return 0; // Stalemate
    }
    
    if (maximizing) {
        var max_eval = -999999;
        for (var i = 0; i < array_length(legal_moves) && !search_cancelled; i++) {
            var move = legal_moves[i];
            var game_state = ai_save_game_state();
            ai_make_move_simulation(move);
            var eval = ai_minimax_window(depth_ - 1, alpha, beta, false);
            ai_restore_game_state(game_state);
            
            max_eval = max(max_eval, eval);
            alpha = max(alpha, eval);
            if (beta <= alpha) break;
        }
        return max_eval;
    } else {
        var min_eval = 999999;
        for (var i = 0; i < array_length(legal_moves) && !search_cancelled; i++) {
            var move = legal_moves[i];
            var game_state = ai_save_game_state();
            ai_make_move_simulation(move);
            var eval = ai_minimax_window(depth_ - 1, alpha, beta, true);
            ai_restore_game_state(game_state);
            
            min_eval = min(min_eval, eval);
            beta = min(beta, eval);
            if (beta <= alpha) break;
        }
        return min_eval;
    }
}
