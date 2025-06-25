/// @function ai_is_stalemate(color)
/// @param {real} color The color to check for stalemate
/// @returns {bool} Whether the color is in stalemate

function ai_is_stalemate(color) {
    if (ai_is_king_in_check(color)) return false;
    
    var legal_moves = ai_get_legal_moves(color);
    return (array_length(legal_moves) == 0);
}