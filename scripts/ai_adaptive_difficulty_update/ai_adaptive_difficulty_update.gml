/// @function ai_adaptive_difficulty_update(player_win_rate)
/// @param {real} player_win_rate Player's win rate (0.0 to 1.0)
/// @description Automatically adjusts difficulty based on player performance

function ai_adaptive_difficulty_update(player_win_rate) {
    var target_win_rate = 0.4; // Target 40% win rate for player
    var current_difficulty = 5; // Default
    
    if (player_win_rate > target_win_rate + 0.2) {
        // Player winning too much, increase difficulty
        current_difficulty = min(current_difficulty + 1, 10);
    } else if (player_win_rate < target_win_rate - 0.2) {
        // Player losing too much, decrease difficulty
        current_difficulty = max(current_difficulty - 1, 1);
    }
    
    ai_set_difficulty(current_difficulty);
    show_debug_message("Adaptive difficulty: " + string(current_difficulty) + 
                      " (player win rate: " + string(player_win_rate * 100) + "%)");
}