/// @function check_for_loops()
/// @description Checks if AI is in a loop
function check_for_loops() {
    show_debug_message("=== LOOP CHECK ===");
    
    if (!instance_exists(AI_Manager)) {
        show_debug_message("AI_Manager not found");
        return false;
    }
    
    var loop_detected = false;
    
    with (AI_Manager) {
        if (variable_instance_exists(id, "ai_move_count") && ai_move_count > 0) {
            show_debug_message("Move count: " + string(ai_move_count) + "/3");
            if (ai_move_count >= 2) {
                loop_detected = true;
            }
        }
        
        if (ai_thinking && variable_instance_exists(id, "think_start_time")) {
            var think_time = current_time - think_start_time;
            show_debug_message("Think time: " + string(think_time) + "ms");
            if (think_time > 3000) {
                loop_detected = true;
            }
        }
    }
    
    if (variable_global_exists("ai_last_moves") && array_length(global.ai_last_moves) >= 3) {
        var recent_moves = [];
        var move_count = array_length(global.ai_last_moves);
        for (var i = max(0, move_count - 3); i < move_count; i++) {
            array_push(recent_moves, global.ai_last_moves[i]);
        }
        show_debug_message("Recent moves: " + string(array_length(recent_moves)));
        for (var i = 0; i < array_length(recent_moves); i++) {
            show_debug_message("  " + string(i + 1) + ": " + recent_moves[i]);
        }
    }
    
    if (loop_detected) {
        show_debug_message("⚠️  LOOP DETECTED!");
        show_debug_message("Run emergency_fix_all() to fix");
    } else {
        show_debug_message("✓ No loop detected");
    }
    
    return loop_detected;
}
