/// @function ai_debug_status()
/// @description Shows current AI status
function ai_debug_status() {
    if (!instance_exists(AI_Manager)) {
        show_debug_message("AI_Manager does not exist!");
        return;
    }
    
    show_debug_message("=== AI STATUS ===");
    show_debug_message("Enabled: " + string(AI_Manager.ai_enabled));
    show_debug_message("Thinking: " + string(AI_Manager.ai_thinking));
    show_debug_message("Search depth: " + string(AI_Manager.search_depth));
    show_debug_message("Max moves considered: " + string(AI_Manager.max_moves_to_consider));
    show_debug_message("Last move time: " + string(AI_Manager.last_move_time) + "ms");
    show_debug_message("Current turn: " + string(Game_Manager.turn));
    show_debug_message("=================");
}