/// @function ai_evaluate_stepping_stones()
/// @returns {real} score_ for stepping stone usage

function ai_evaluate_stepping_stones() {
    var score__ = 0;
    
    with (Stepping_Stone_Obj) {
        if (instance_exists(id)) {
            // Stepping stones provide tactical opportunities
            var stone_value = 25;
            
            // Check if any piece can use this stone
            var black_can_use = false;
            var white_can_use = false;
            
            with (Chess_Piece_Obj) {
                if (instance_exists(id)) {
                    var distance = point_distance(x, y, other.x, other.y);
                    if (distance <= Board_Manager.tile_size * 2) {
                        if (piece_type == 1) {
                            black_can_use = true;
                        } else {
                            white_can_use = true;
                        }
                    }
                }
            }
            
            if (black_can_use && !white_can_use) {
                score_ += stone_value;
            } else if (white_can_use && !black_can_use) {
                score_ -= stone_value;
            }
        }
    }
    
    return score_;
}