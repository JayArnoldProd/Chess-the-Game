/// @function ai_get_current_difficulty()
/// @returns {real} Current difficulty level (1-10)
function ai_get_current_difficulty() {
    if (!instance_exists(AI_Manager)) return 1;
    
    // Estimate difficulty based on current settings
    var depth_ = AI_Manager.search_depth;
    var moves = AI_Manager.max_moves_to_consider;
    
    if (depth_ <= 1 && moves <= 5) return 1;
    if (depth_ <= 2 && moves <= 8) return 2;
    if (depth_ <= 2 && moves <= 10) return 3;
    if (depth_ <= 3 && moves <= 12) return 4;
    if (depth_ <= 3 && moves <= 15) return 5;
    if (depth_ <= 4 && moves <= 18) return 6;
    if (depth_ <= 4 && moves <= 20) return 7;
    if (depth_ <= 5 && moves <= 25) return 8;
    if (depth_ <= 6 && moves <= 30) return 9;
    return 10;
}