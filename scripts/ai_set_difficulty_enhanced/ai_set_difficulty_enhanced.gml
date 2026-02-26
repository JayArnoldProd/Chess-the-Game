/// @function ai_set_difficulty_enhanced(level)
/// @description Sets AI difficulty with time-based search
function ai_set_difficulty_enhanced(level) {
    if (!instance_exists(AI_Manager)) return;
    
    level = clamp(level, 1, 5);
    
    with (AI_Manager) {
        switch (level) {
            case 1: 
                ai_time_limit = 0;
                max_moves_to_consider = 4; 
                break;
            case 2: 
                ai_time_limit = 500;
                max_moves_to_consider = 6; 
                break;  
            case 3: 
                ai_time_limit = 1000;
                max_moves_to_consider = 8; 
                break;
            case 4: 
                ai_time_limit = 2000;
                max_moves_to_consider = 10; 
                break;
            case 5: 
                ai_time_limit = 5000;
                max_moves_to_consider = 12; 
                break;
        }
    }
    
    ai_tt_clear();
    show_debug_message("AI difficulty set to " + string(level) + " (time limit: " + string(AI_Manager.ai_time_limit) + "ms)");
}
