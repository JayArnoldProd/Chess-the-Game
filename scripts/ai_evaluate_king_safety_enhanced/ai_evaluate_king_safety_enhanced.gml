/// @function ai_evaluate_king_safety_enhanced()
/// @returns {real} Enhanced king safety evaluation

function ai_evaluate_king_safety_enhanced() {
    var score__ = 0;
    
    // Evaluate both kings
    with (King_Obj) {
        if (instance_exists(id)) {
            var safety_score = 0;
            
            // Basic king safety
            var attackers_nearby = 0;
            var defenders_nearby = 0;
            
            with (Chess_Piece_Obj) {
                if (instance_exists(id) && id != other.id) {
                    var distance = point_distance(x, y, other.x, other.y);
                    if (distance <= Board_Manager.tile_size * 3) {
                        if (piece_type == other.piece_type) {
                            defenders_nearby++;
                        } else {
                            attackers_nearby++;
                        }
                    }
                }
            }
            
            safety_score = (defenders_nearby * 15) - (attackers_nearby * 25);
            
            // Special mechanics king safety
            // Check for water/void nearby (dangerous)
            var danger_tiles = 0;
            for (var dx = -1; dx <= 1; dx++) {
                for (var dy = -1; dy <= 1; dy++) {
                    var check_x = x + dx * Board_Manager.tile_size;
                    var check_y = y + dy * Board_Manager.tile_size;
                    var tile = instance_place(check_x, check_y, Tile_Obj);
                    
                    if (tile) {
                        if (tile.tile_type == -1) { // Void
                            danger_tiles += 2;
                        } else if (tile.tile_type == 1) { // Water
                            if (!instance_position(check_x + Board_Manager.tile_size/4, 
                                                 check_y + Board_Manager.tile_size/4, Bridge_Obj)) {
                                danger_tiles += 1;
                            }
                        }
                    }
                }
            }
            
            safety_score -= danger_tiles * 30;
            
            // Apply score_ based on king color
            if (piece_type == 1) { // Black king
                score_ += safety_score;
            } else { // White king
                score_ -= safety_score;
            }
        }
    }
    
    return score_;
}