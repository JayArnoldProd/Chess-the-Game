/// @function ai_is_square_attacked(target_x, target_y, friendly_color)
function ai_is_square_attacked(target_x, target_y, friendly_color) {
    var enemy_color = (friendly_color == 0) ? 1 : 0;
    
    // Check if any enemy piece can attack this square
    with (Chess_Piece_Obj) {
        if (instance_exists(id) && piece_type == enemy_color) {
            for (var i = 0; i < array_length(valid_moves); i++) {
                var move = valid_moves[i];
                var attack_x = x + move[0] * Board_Manager.tile_size;
                var attack_y = y + move[1] * Board_Manager.tile_size;
                
                if (point_distance(attack_x, attack_y, target_x, target_y) < Board_Manager.tile_size / 2) {
                    return true; // Square is under attack
                }
            }
        }
    }
    
    return false; // Square is safe
}