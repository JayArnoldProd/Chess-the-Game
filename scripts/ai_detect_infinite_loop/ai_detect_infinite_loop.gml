/// @function ai_detect_infinite_loop()
/// @description Detects if AI is in an infinite loop
function ai_detect_infinite_loop() {
    if (!instance_exists(AI_Manager)) return false;
    
    var is_looping = false;
    
    with (AI_Manager) {
        if (variable_instance_exists(id, "ai_move_count") && ai_move_count > 3) {
            is_looping = true;
        }
        
        if (ai_thinking && variable_instance_exists(id, "think_start_time")) {
            var think_time = current_time - think_start_time;
            if (think_time > 3000) { // 3+ seconds thinking
                is_looping = true;
            }
        }
    }
    
    // Check if same piece keeps moving
    var knight_positions = [];
    with (Knight_Obj) {
        if (piece_type == 1) { // Black knight
            array_push(knight_positions, [x, y]);
        }
    }
    
    if (array_length(knight_positions) > 0) {
        show_debug_message("Black knight position: " + 
                          string(knight_positions[0][0]) + "," + 
                          string(knight_positions[0][1]));
    }
    
    return is_looping;
}
