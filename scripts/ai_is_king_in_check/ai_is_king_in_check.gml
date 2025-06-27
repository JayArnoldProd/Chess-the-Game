/// @function ai_is_king_in_check(color)
function ai_is_king_in_check(color) {
    // Find the king
    var king = noone;
    with (King_Obj) {
        if (instance_exists(id) && piece_type == color) {
            king = id;
            break;
        }
    }
    
    if (king == noone || !instance_exists(king)) return true; // No king = bad
    
    // Check if king's square is attacked
    return ai_is_square_attacked(king.x, king.y, color);
}
