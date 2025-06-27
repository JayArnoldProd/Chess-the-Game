/// @function force_ai_move_now()
/// @description Forces AI to make a move immediately
function force_ai_move_now() {
    show_debug_message("=== FORCING AI MOVE ===");
    
    if (Game_Manager.turn != 1) {
        Game_Manager.turn = 1;
        show_debug_message("Switched to AI turn");
    }
    
    if (!instance_exists(AI_Manager)) {
        show_debug_message("ERROR: AI_Manager not found");
        return;
    }
    
    with (AI_Manager) {
        // Reset AI state
        ai_thinking = false;
        ai_selected_move = undefined;
        ai_move_delay = 0;
        ai_cooldown = 0;
        if (variable_instance_exists(id, "ai_move_count")) ai_move_count = 0;
        
        // Force simple mode for reliability
        ai_simple_mode = true;
    }
    
    show_debug_message("AI forced to move in simple mode");
}