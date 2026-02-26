/// @function ai_is_king_in_check_simple(color)
/// @param {real} color King color to check
/// @returns {bool} Whether king is in check
function ai_is_king_in_check_simple(color) {
    var king = noone;
    with (King_Obj) {
        if (instance_exists(id) && piece_type == color) {
            king = id;
            break;
        }
    }
    
    if (king == noone || !instance_exists(king)) return true;
    
    // Check if any enemy piece can attack the king
    var enemy_color = (color == 0) ? 1 : 0;
    with (Chess_Piece_Obj) {
        if (instance_exists(id) && piece_type == enemy_color) {
            for (var i = 0; i < array_length(valid_moves); i++) {
                var move = valid_moves[i];
                var attack_x = x + move[0] * Board_Manager.tile_size;
                var attack_y = y + move[1] * Board_Manager.tile_size;
                
                if (point_distance(attack_x, attack_y, king.x, king.y) < Board_Manager.tile_size / 2) {
                    return true;
                }
            }
        }
    }
    
    return false;
}