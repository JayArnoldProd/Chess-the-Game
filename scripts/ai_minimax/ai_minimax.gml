/// @function ai_minimax(depth, alpha, beta, maximizing_player)
/// @param {real} depth Current search depth
/// @param {real} alpha Alpha value for pruning
/// @param {real} beta Beta value for pruning
/// @param {bool} maximizing_player Whether current player is maximizing
/// @returns {real} The evaluation score

function ai_minimax(depth, alpha, beta, maximizing_player) {
    // Terminal conditions
    if (depth == 0) {
        return ai_quiescence_search(alpha, beta, maximizing_player, 4);
    }
    
    var current_color = maximizing_player ? 1 : 0;
    
    // Check for checkmate/stalemate
    if (ai_is_checkmate(current_color)) {
        return maximizing_player ? -999999 + (AI_Manager.ai_depth - depth) : 999999 - (AI_Manager.ai_depth - depth);
    }
    
    if (ai_is_stalemate(current_color)) {
        return 0; // Stalemate is a draw
    }
    
    var legal_moves = ai_get_legal_moves(current_color);
    
    if (array_length(legal_moves) == 0) {
        return ai_evaluate_board();
    }
    
    // Order moves for better pruning
    legal_moves = ai_order_moves(legal_moves);
    
    if (maximizing_player) {
        var max_eval = -999999;
        
        for (var i = 0; i < array_length(legal_moves); i++) {
            var move = legal_moves[i];
            var game_state = ai_save_game_state();
            
            ai_make_move_simulation(move);
            var eval = ai_minimax(depth - 1, alpha, beta, false);
            ai_restore_game_state(game_state);
            
            max_eval = max(max_eval, eval);
            alpha = max(alpha, eval);
            
            if (beta <= alpha) {
                break; // Beta cutoff
            }
        }
        
        return max_eval;
    } else {
        var min_eval = 999999;
        
        for (var i = 0; i < array_length(legal_moves); i++) {
            var move = legal_moves[i];
            var game_state = ai_save_game_state();
            
            ai_make_move_simulation(move);
            var eval = ai_minimax(depth - 1, alpha, beta, true);
            ai_restore_game_state(game_state);
            
            min_eval = min(min_eval, eval);
            beta = min(beta, eval);
            
            if (beta <= alpha) {
                break; // Alpha cutoff
            }
        }
        
        return min_eval;
    }
}

