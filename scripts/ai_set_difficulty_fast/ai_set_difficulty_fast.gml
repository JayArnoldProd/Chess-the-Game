/// @function ai_set_difficulty_fast(level)
/// @param {real} level Difficulty from 1-5
/// @description Sets AI difficulty quickly

function ai_set_difficulty_fast(level) {
    level = clamp(level, 1, 5);
    
    switch (level) {
        case 1: // Beginner
            AI_Manager.max_moves_to_consider = 5;
            AI_Manager.search_depth = 1;
            break;
        case 2: // Easy  
            AI_Manager.max_moves_to_consider = 8;
            AI_Manager.search_depth = 1;
            break;
        case 3: // Medium
            AI_Manager.max_moves_to_consider = 10;
            AI_Manager.search_depth = 2;
            break;
        case 4: // Hard
            AI_Manager.max_moves_to_consider = 12;
            AI_Manager.search_depth = 2;
            break;
        case 5: // Expert
            AI_Manager.max_moves_to_consider = 15;
            AI_Manager.search_depth = 2;
            break;
    }
    
    show_debug_message("AI difficulty set to " + string(level));
}