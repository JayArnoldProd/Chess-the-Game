/// @function ai_get_legal_moves(color)
/// @param {real} color The color to get legal moves for
/// @returns {array} Array of legal moves

function ai_get_legal_moves(color) {
    var all_moves = ai_generate_moves(color);
    var legal_moves = [];
    
    for (var i = 0; i < array_length(all_moves); i++) {
        if (ai_is_legal_move(all_moves[i])) {
            array_push(legal_moves, all_moves[i]);
        }
    }
    
    return legal_moves;
}