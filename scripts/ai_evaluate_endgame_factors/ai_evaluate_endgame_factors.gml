/// @function ai_evaluate_endgame_factors()
/// @returns {real} Endgame evaluation adjustments

function ai_evaluate_endgame_factors() {
    var score_ = 0;
    
    // In endgame, king activity is important
    with (King_Obj) {
        if (instance_exists(id)) {
            var centralization = 0;
            var grid_x = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
            var grid_y = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
            
            // Encourage king centralization in endgame
            var distance_from_center = abs(grid_x - 3.5) + abs(grid_y - 3.5);
            centralization = (7 - distance_from_center) * 10;
            
            if (piece_type == 1) { // Black king
                score_ += centralization;
            } else { // White king
                score_ -= centralization;
            }
        }
    }
    
    // Passed pawns are very important in endgame
    score_ += ai_evaluate_passed_pawns_endgame();
    
    return score_;
}
