/// @function ai_should_use_fast_mode()
/// @returns {bool} Whether to use fast algorithm - FIXED
function ai_should_use_fast_mode() {
    // Use fast mode for simple positions or low difficulty
    if (search_depth <= 2) return true;
    if (position_complexity < 20) return true;
    
    // Use fast mode if time pressure
    if (time_pressure) return true;
    
    // Use fast mode for obvious moves - SAFELY
    try {
        var legal_moves = ai_get_legal_moves_fast(1);
        if (array_length(legal_moves) <= 3) return true;
        
        // Check for forced moves (only one good option)
        var good_moves = 0;
        for (var i = 0; i < min(5, array_length(legal_moves)); i++) {
            var score_ = ai_score_move_fast(legal_moves[i]);
            if (score_ > 100) good_moves++;
        }
        if (good_moves <= 1) return true;
        
    } catch (error) {
        show_debug_message("Error in fast mode check: " + string(error));
        return true; // Default to fast mode on error
    }
    
    return false;
}