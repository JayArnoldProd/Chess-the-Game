/// @function ai_set_difficulty_enhanced(level)
function ai_set_difficulty_enhanced(level) {
    if (!instance_exists(AI_Manager)) return;
    
    level = clamp(level, 1, 5); // Limit to 5 levels max
    
    with (AI_Manager) {
        switch (level) {
            case 1: max_moves_to_consider = 4; break;
            case 2: max_moves_to_consider = 6; break;  
            case 3: max_moves_to_consider = 8; break;
            case 4: max_moves_to_consider = 10; break;
            case 5: max_moves_to_consider = 12; break;
        }
    }
    
    show_debug_message("AI difficulty set to " + string(level));
}
