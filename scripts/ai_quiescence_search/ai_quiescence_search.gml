/// @function ai_quiescence_search(alpha, beta, maximizing_player, depth)
/// @param {real} alpha Alpha value
/// @param {real} beta Beta value  
/// @param {bool} maximizing_player Whether maximizing
/// @param {real} depth Remaining quiescence depth
/// @returns {real} Evaluation score

function ai_quiescence_search(alpha, beta, maximizing_player, depth) {
    var stand_pat = ai_evaluate_board();
    
    if (depth == 0) {
        return stand_pat;
    }
    
    if (maximizing_player) {
        if (stand_pat >= beta) {
            return beta;
        }
        alpha = max(alpha, stand_pat);
    } else {
        if (stand_pat <= alpha) {
            return alpha;
        }
        beta = min(beta, stand_pat);
    }
    
    var current_color = maximizing_player ? 1 : 0;
    var legal_moves = ai_get_legal_moves(current_color);
    var capture_moves = [];
    
    // Only consider captures and checks in quiescence search
    for (var i = 0; i < array_length(legal_moves); i++) {
        if (legal_moves[i].is_capture) {
            array_push(capture_moves, legal_moves[i]);
        }
    }
    
    if (array_length(capture_moves) == 0) {
        return stand_pat;
    }
    
    capture_moves = ai_order_moves(capture_moves);
    
    if (maximizing_player) {
        for (var i = 0; i < array_length(capture_moves); i++) {
            var move = capture_moves[i];
            var game_state = ai_save_game_state();
            
            ai_make_move_simulation(move);
            var score_ = ai_quiescence_search(alpha, beta, false, depth - 1);
            ai_restore_game_state(game_state);
            
            if (score_ >= beta) {
                return beta;
            }
            alpha = max(alpha, score_);
        }
        return alpha;
    } else {
        for (var i = 0; i < array_length(capture_moves); i++) {
            var move = capture_moves[i];
            var game_state = ai_save_game_state();
            
            ai_make_move_simulation(move);
            var score_ = ai_quiescence_search(alpha, beta, true, depth - 1);
            ai_restore_game_state(game_state);
            
            if (score_ <= alpha) {
                return alpha;
            }
            beta = min(beta, score_);
        }
        return beta;
    }
}
