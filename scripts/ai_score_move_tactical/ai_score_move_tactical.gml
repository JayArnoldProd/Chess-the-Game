/// @function ai_score_move_tactical(move)
/// @param {struct} move The move to score tactically - FIXED
/// @returns {real} Tactical score
function ai_score_move_tactical(move) {
    try {
        var score_ = ai_score_move_fast(move);
        
        // Enhanced tactical evaluation
        if (move.is_capture && move.captured_piece != noone && instance_exists(move.captured_piece)) {
            // SEE (Static Exchange Evaluation) approximation
            var attacker_value = ds_map_find_value(piece_values, move.piece_id);
            var victim_value = ds_map_find_value(piece_values, move.captured_piece.piece_id);
            
            if (victim_value >= attacker_value) {
                score_ += 200; // Good trade
            } else {
                score_ -= 50; // Risky trade
            }
        }
        
        // Tactical patterns (simplified for now)
        if (ai_move_creates_threat(move)) score_ += 100;
        if (ai_move_improves_position(move)) score_ += 50;
        
        return score_;
        
    } catch (error) {
        show_debug_message("Error in tactical scoring: " + string(error));
        return 0; // Neutral score on error
    }
}