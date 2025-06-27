/// @function ai_pick_best_move_fast(moves)
/// @param {array} moves Array of legal moves
/// @returns {struct} Best move

function ai_pick_best_move_fast(moves) {
    if (array_length(moves) == 0) return undefined;
    
    // Score each move quickly
    var best_move = moves[0];
    var best_score = -999999;
    
    // Limit moves considered for speed
    var moves_to_check = min(array_length(moves), AI_Manager.max_moves_to_consider);
    
    for (var i = 0; i < moves_to_check; i++) {
        var move = moves[i];
        var score_ = ai_score_move_fast(move);
        
        if (score_ > best_score) {
            best_score = score_;
            best_move = move;
        }
    }
    
    // Add a bit of randomness to avoid predictable play
    if (irandom(100) < 20) { // 20% chance
        var random_index = irandom(min(5, array_length(moves) - 1));
        best_move = moves[random_index];
        show_debug_message("AI: Using random move for variety");
    }
    
    return best_move;
}
