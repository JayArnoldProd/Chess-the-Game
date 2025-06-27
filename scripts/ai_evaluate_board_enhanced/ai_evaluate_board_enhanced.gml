/// @function ai_evaluate_board_enhanced()
/// @description Enhanced evaluation for special chess mechanics
/// @returns {real} The evaluation score_ (positive favors black, negative favors white)

function ai_evaluate_board_enhanced() {
    var score_ = 0;
    var white_pieces = 0;
    var black_pieces = 0;
    
    // Basic material and positional evaluation
    with (Chess_Piece_Obj) {
        if (instance_exists(id)) {
            var piece_value = AI_Manager.piece_values[$ piece_id];
            var positional_bonus = ai_get_positional_bonus(id);
            
            if (piece_type == 1) { // Black (AI)
                black_pieces++;
                score_ += piece_value + positional_bonus;
            } else { // White (Player)
                white_pieces++;
                score_ -= piece_value + positional_bonus;
            }
        }
    }
    
    // Special mechanics evaluation
    score_ += ai_evaluate_water_control();
    score_ += ai_evaluate_bridge_control();
    score_ += ai_evaluate_stepping_stones();
    score_ += ai_evaluate_conveyor_belt_positioning();
    score_ += ai_evaluate_king_safety_enhanced();
    
    // Endgame adjustments
    var total_pieces = white_pieces + black_pieces;
    if (total_pieces <= 12) {
        score_ += ai_evaluate_endgame_factors();
    }
    
    return score_;
}