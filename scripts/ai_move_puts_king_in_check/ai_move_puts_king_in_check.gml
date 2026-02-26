/// @function ai_move_puts_king_in_check(move)
/// @param {struct} move The king move to test
/// @returns {bool} Whether this move puts king in check
function ai_move_puts_king_in_check(move) {
    if (move.piece_id != "king") return false;
    
    // Check if any enemy piece can attack the target square
    var enemy_color = (move.piece_type == 0) ? 1 : 0;
    with (Chess_Piece_Obj) {
        if (instance_exists(id) && piece_type == enemy_color) {
            for (var i = 0; i < array_length(valid_moves); i++) {
                var attack_move = valid_moves[i];
                var attack_x = x + attack_move[0] * Board_Manager.tile_size;
                var attack_y = y + attack_move[1] * Board_Manager.tile_size;
                
                if (point_distance(attack_x, attack_y, move.to_x, move.to_y) < Board_Manager.tile_size / 2) {
                    return true;
                }
            }
        }
    }
    
    return false;
}