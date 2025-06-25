/// @function ai_evaluate_center_control()
/// @returns {real} Center control score difference (positive for black)

function ai_evaluate_center_control_safe() {
    var center_score = 0;
    
    // Skip center control evaluation if managers don't exist
    if (!instance_exists(Object_Manager) || !instance_exists(Board_Manager)) {
        return 0;
    }
    
    var center_squares = [
        [3, 3], [3, 4], [4, 3], [4, 4] // d4, d5, e4, e5
    ];
    
    for (var i = 0; i < array_length(center_squares); i++) {
        var cx = Object_Manager.topleft_x + center_squares[i][0] * Board_Manager.tile_size;
        var cy = Object_Manager.topleft_y + center_squares[i][1] * Board_Manager.tile_size;
        
        var piece = instance_position(cx, cy, Chess_Piece_Obj);
        if (piece != noone && instance_exists(piece)) {
            if (piece.piece_type == 1) { // Black
                center_score += 30;
            } else { // White
                center_score -= 30;
            }
        }
        
        // Count pieces attacking center squares safely
        var black_attackers = 0;
        var white_attackers = 0;
        
        with (Chess_Piece_Obj) {
            if (instance_exists(id) && is_array(valid_moves)) {
                for (var j = 0; j < array_length(valid_moves); j++) {
                    var target_x = x + valid_moves[j][0] * Board_Manager.tile_size;
                    var target_y = y + valid_moves[j][1] * Board_Manager.tile_size;
                    
                    if (point_distance(target_x, target_y, cx, cy) < Board_Manager.tile_size / 2) {
                        if (piece_type == 1) {
                            black_attackers++;
                        } else {
                            white_attackers++;
                        }
                    }
                }
            }
        }
        
        center_score += (black_attackers - white_attackers) * 5;
    }
    
    return center_score;
}