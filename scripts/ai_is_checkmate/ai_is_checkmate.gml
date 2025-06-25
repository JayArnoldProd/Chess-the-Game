/// @function ai_is_checkmate(color)
/// @param {real} color The color to check for checkmate
/// @returns {bool} Whether the color is in checkmate

function ai_is_checkmate(color) {
    if (!ai_is_king_in_check(color)) return false;
    
    var legal_moves = ai_get_legal_moves(color);
    return (array_length(legal_moves) == 0);
}
