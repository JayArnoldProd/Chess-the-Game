/// @function ai_update_performance_metrics() - FIXED
function ai_update_performance_metrics() {
    try {
        // Track move time
        array_push(time_per_move_history, last_move_time);
        if (array_length(time_per_move_history) > 10) {
            array_delete(time_per_move_history, 0, 1);
        }
        
        // Track complexity
        array_push(move_complexity_history, position_complexity);
        if (array_length(move_complexity_history) > 10) {
            array_delete(move_complexity_history, 0, 1);
        }
        
        // Update search efficiency
        if (last_move_time > 0 && time_budget > 0) {
            var efficiency = time_budget / max(last_move_time, 1);
            search_efficiency = lerp(search_efficiency, efficiency, 0.3);
        }
        
    } catch (error) {
        show_debug_message("Error updating performance metrics: " + string(error));
    }
}
