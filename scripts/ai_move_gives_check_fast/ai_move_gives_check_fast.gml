/// @function ai_move_gives_check_fast(move)
/// @param {struct} move The move to check
/// @returns {bool} Whether move gives check

function ai_move_gives_check_fast(move) {
    // Very simple check detection
    // Find enemy king
    var enemy_king = noone;
    with (King_Obj) {
        if (instance_exists(id) && piece_type != move.piece_type) {
            enemy_king = id;
            break;
        }
    }
    
    if (enemy_king == noone) return false;
    
    // Simple distance check for some pieces
    var distance = point_distance(move.to_x, move.to_y, enemy_king.x, enemy_king.y);
    
    switch (move.piece_id) {
        case "queen":
        case "rook":
            // Check if on same rank or file
            return (abs(move.to_x - enemy_king.x) < Board_Manager.tile_size/2 || 
                   abs(move.to_y - enemy_king.y) < Board_Manager.tile_size/2);
            
        case "bishop":
            // Check if on diagonal
            return (abs(move.to_x - enemy_king.x) == abs(move.to_y - enemy_king.y));
            
        case "knight":
            // Check knight move pattern
            var dx = abs(move.to_x - enemy_king.x) / Board_Manager.tile_size;
            var dy = abs(move.to_y - enemy_king.y) / Board_Manager.tile_size;
            return ((dx == 2 && dy == 1) || (dx == 1 && dy == 2));
    }
    
    return false;
}
