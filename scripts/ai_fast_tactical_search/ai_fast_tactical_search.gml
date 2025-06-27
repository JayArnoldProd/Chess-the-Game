/// @function ai_fast_tactical_search()
/// @returns {struct} Best move from fast search - FIXED
function ai_fast_tactical_search() {
    try {
        var legal_moves = ai_get_legal_moves_fast(1);
        
        if (array_length(legal_moves) == 0) return undefined;
        
        // Quick tactical evaluation
        var best_move = legal_moves[0];
        var best_score = -999999;
        
        // Prioritize captures and threats
        var moves_to_check = min(array_length(legal_moves), max_moves_to_consider);
        
        for (var i = 0; i < moves_to_check; i++) {
            var move = legal_moves[i];
            var score_ = ai_score_move_tactical(move);
            
            if (score_ > best_score) {
                best_score = score_;
                best_move = move;
            }
        }
        
        return best_move;
        
    } catch (error) {
        show_debug_message("Error in fast tactical search: " + string(error));
        // Emergency fallback
        var moves = ai_get_legal_moves_fast(1);
        if (array_length(moves) > 0) {
            return moves[0]; // Return first legal move
        }
        return undefined;
    }
}