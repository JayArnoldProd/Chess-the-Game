/// @function ai_set_difficulty(level)
/// @param {real} level Difficulty level (1-10)
/// @description Sets AI difficulty and performance parameters

function ai_set_difficulty(level) {
    level = clamp(level, 1, 10);
    
    switch (level) {
        case 1: // Beginner
            max_depth = 3;
            max_think_time = 500;
            frame_budget = 4;
            break;
        case 2: // Easy
            max_depth = 4;
            max_think_time = 750;
            frame_budget = 6;
            break;
        case 3: // Medium-Easy
            max_depth = 5;
            max_think_time = 1000;
            frame_budget = 8;
            break;
        case 4: // Medium
            max_depth = 6;
            max_think_time = 1500;
            frame_budget = 10;
            break;
        case 5: // Medium-Hard
            max_depth = 7;
            max_think_time = 2000;
            frame_budget = 12;
            break;
        case 6: // Hard
            max_depth = 8;
            max_think_time = 2500;
            frame_budget = 14;
            break;
        case 7: // Very Hard
            max_depth = 9;
            max_think_time = 3000;
            frame_budget = 16;
            break;
        case 8: // Expert
            max_depth = 10;
            max_think_time = 4000;
            frame_budget = 20;
            break;
        case 9: // Master
            max_depth = 12;
            max_think_time = 5000;
            frame_budget = 25;
            break;
        case 10: // Grandmaster
            max_depth = 15;
            max_think_time = 8000;
            frame_budget = 30;
            break;
    }
    
    show_debug_message("AI difficulty set to " + string(level) + 
                      " (depth: " + string(max_depth) + 
                      ", time: " + string(max_think_time) + "ms)");
}