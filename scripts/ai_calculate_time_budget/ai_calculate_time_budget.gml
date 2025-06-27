/// @function ai_calculate_time_budget()
/// @returns {real} Time to spend thinking in milliseconds - FIXED
function ai_calculate_time_budget() {
    var base_time = 500; // Base time per difficulty level
    base_time *= search_depth;
    
    // Adjust for position complexity
    base_time *= (1 + position_complexity / 100);
    
    // Adjust for game phase
    var piece_count = instance_number(Chess_Piece_Obj);
    if (piece_count <= 12) base_time *= 1.5; // More time in endgame
    
    // Adjust for previous performance - FIXED
    if (array_length(time_per_move_history) > 0) {
        var avg_time = array_sum_custom(time_per_move_history) / array_length(time_per_move_history);
        if (avg_time > base_time * 1.5) base_time *= 0.8; // Speed up if too slow
    }
    
    return clamp(base_time, 200, 5000);
}
