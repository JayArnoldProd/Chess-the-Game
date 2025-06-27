/// @function ai_evaluate_conveyor_belt_positioning()
/// @returns {real} score_ for conveyor belt positioning

function ai_evaluate_conveyor_belt_positioning() {
    var score_ = 0;
    
    with (Factory_Belt_Obj) {
        if (instance_exists(id)) {
            // Pieces on conveyor belts can be moved involuntarily
            var belt_penalty = 20;
            
            with (Chess_Piece_Obj) {
                if (instance_exists(id)) {
                    // Check if piece is on this belt
                    if (x >= other.x && x < other.x + other.sprite_width &&
                        y >= other.y && y < other.y + other.sprite_height) {
                        
                        if (piece_type == 1) { // Black on belt
                            score_ -= belt_penalty;
                        } else { // White on belt
                            score_ += belt_penalty;
                        }
                    }
                }
            }
        }
    }
    
    return score_;
}