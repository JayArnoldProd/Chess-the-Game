/// @function ai_evaluate_bridge_control()
/// @returns {real} score_ for bridge control

function ai_evaluate_bridge_control() {
    var score__ = 0;
    
    with (Bridge_Obj) {
        if (instance_exists(id)) {
            var control_value = 30;
            
            // Check which side controls this bridge
            var white_control = 0;
            var black_control = 0;
            
            // Check pieces near bridge
            with (Chess_Piece_Obj) {
                if (instance_exists(id)) {
                    var distance = point_distance(x, y, other.x, other.y);
                    if (distance <= Board_Manager.tile_size * 2) {
                        if (piece_type == 0) {
                            white_control++;
                        } else {
                            black_control++;
                        }
                    }
                }
            }
            
            if (black_control > white_control) {
                score_ += control_value;
            } else if (white_control > black_control) {
                score_ -= control_value;
            }
        }
    }
    
    return score_;
}