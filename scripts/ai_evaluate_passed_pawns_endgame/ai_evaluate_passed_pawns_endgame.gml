/// @function ai_evaluate_passed_pawns_endgame()
/// @returns {real} Passed pawn evaluation for endgame

function ai_evaluate_passed_pawns_endgame() {
    var score_ = 0;
    
    with (Pawn_Obj) {
        if (instance_exists(id)) {
            if (ai_is_passed_pawn(id)) {
                var bonus = 100;
                var rank = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
                
                if (piece_type == 0) { // White pawn
                    bonus += (7 - rank) * 20; // Closer to promotion = more valuable
                    score_ -= bonus;
                } else { // Black pawn
                    bonus += rank * 20;
                    score_ += bonus;
                }
            }
        }
    }
    
    return score_;
}