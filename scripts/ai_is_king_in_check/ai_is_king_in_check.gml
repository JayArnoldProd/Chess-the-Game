/// @function ai_is_king_in_check(color)
/// @param {real} color The color of the king to check (0 = white, 1 = black)
/// @returns {bool} Whether the king is in check

function ai_is_king_in_check(color) {
    var king = noone;
    
    // Find the king safely
    with (King_Obj) {
        if (instance_exists(id) && piece_type == color) {
            king = id;
            break;
        }
    }
    
    if (king == noone || !instance_exists(king)) return true; // King doesn't exist = check
    
    var king_x = king.x;
    var king_y = king.y;
    
    // Check if any enemy piece can attack the king
    with (Chess_Piece_Obj) {
        if (instance_exists(id) && piece_type != color) {
            // Safely check valid moves
            if (variable_instance_exists(id, "valid_moves") && is_array(valid_moves)) {
                for (var i = 0; i < array_length(valid_moves); i++) {
                    if (i < array_length(valid_moves) && is_array(valid_moves[i])) {
                        var move = valid_moves[i];
                        if (array_length(move) >= 2) {
                            var target_x = x + move[0] * Board_Manager.tile_size;
                            var target_y = y + move[1] * Board_Manager.tile_size;
                            
                            if (point_distance(target_x, target_y, king_x, king_y) < Board_Manager.tile_size / 2) {
                                return true;
                            }
                        }
                    }
                }
            }
        }
    }
    
    return false;
}