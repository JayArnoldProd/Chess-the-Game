/// @function ai_set_difficulty_simple(level)
/// @param {real} level Difficulty level 1-5
/// @description Difficulty system with time-based multi-frame search
function ai_set_difficulty_simple(level) {
    if (!instance_exists(AI_Manager)) return;
    
    level = clamp(level, 1, 5);
    
    with (AI_Manager) {
        switch (level) {
            case 1: // Beginner - instant (heuristic only)
                ai_time_limit = 0;
                max_moves_to_consider = 3;
                ai_move_delay = 30;
                break;
            case 2: // Easy - 0.5 seconds
                ai_time_limit = 500;
                max_moves_to_consider = 5;
                ai_move_delay = 15;
                break;
            case 3: // Medium - 2 seconds
                ai_time_limit = 2000;
                max_moves_to_consider = 8;
                ai_move_delay = 15;
                break;
            case 4: // Hard - 10 seconds
                ai_time_limit = 10000;
                max_moves_to_consider = 12;
                ai_move_delay = 10;
                break;
            case 5: // Grandmaster - 30 seconds
                ai_time_limit = 30000;
                max_moves_to_consider = 15;
                ai_move_delay = 10;
                break;
        }
    }
    
    // Store current difficulty level globally for UI
    global.ai_difficulty_level = level;
    
    // Clear transposition table on difficulty change
    ai_tt_clear();
    
    var time_str = AI_Manager.ai_time_limit == 0 ? "instant" : string(AI_Manager.ai_time_limit / 1000) + "s";
    show_debug_message("AI difficulty set to " + string(level) + " (" + time_str + ")");
}

/// @function ai_get_difficulty_name(level)
/// @param {real} level Difficulty level 1-5
/// @returns {string} Human-readable difficulty name
function ai_get_difficulty_name(level) {
    switch (level) {
        case 1: return "Beginner (Instant)";
        case 2: return "Easy (0.5s)";
        case 3: return "Medium (2s)";
        case 4: return "Hard (10s)";
        case 5: return "Grandmaster (30s)";
        default: return "Unknown";
    }
}
