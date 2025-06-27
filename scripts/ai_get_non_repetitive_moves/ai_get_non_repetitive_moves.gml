/// @function ai_get_non_repetitive_moves(color)
/// @param {real} color The color to get moves for
/// @returns {array} Array of legal moves excluding recent repeats

function ai_get_non_repetitive_moves(color) {
    var all_moves = ai_get_legal_moves_fast_fixed(color);
    var filtered_moves = [];
    
    for (var i = 0; i < array_length(all_moves); i++) {
        var move = all_moves[i];
        
        // Skip if move is repetitive
        if (ai_is_move_repetitive(move)) {
            show_debug_message("Skipping repetitive move: " + move.piece_id);
            continue;
        }
        
        array_push(filtered_moves, move);
    }
    
    // If no non-repetitive moves, return all moves to prevent getting stuck
    if (array_length(filtered_moves) == 0) {
        show_debug_message("No non-repetitive moves, using all moves");
        return all_moves;
    }
    
    return filtered_moves;
}

