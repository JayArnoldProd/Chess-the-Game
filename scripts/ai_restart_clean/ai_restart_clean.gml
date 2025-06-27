/// @function ai_restart_clean()
/// @description Completely restarts AI system cleanly
function ai_restart_clean() {
    show_debug_message("=== CLEAN AI RESTART ===");
    
    // Stop everything first
    ai_emergency_stop();
    
    // Fix stuck pieces
    ai_fix_stuck_pieces();
    
    // Reset AI_Manager completely
    if (instance_exists(AI_Manager)) {
        with (AI_Manager) {
            ai_enabled = true;
            ai_thinking = false;
            ai_move_delay = 0;
            ai_selected_move = undefined;
            search_depth = 2;
            max_moves_to_consider = 10;
            
            // Clear enhanced variables
            if (variable_instance_exists(id, "ai_move_count")) ai_move_count = 0;
            if (variable_instance_exists(id, "ai_last_turn_check")) ai_last_turn_check = -1;
            if (variable_instance_exists(id, "ai_cooldown")) ai_cooldown = 0;
            if (variable_instance_exists(id, "think_start_time")) think_start_time = 0;
            
            show_debug_message("AI_Manager reset");
        }
    }
    
    // Ensure it's player's turn
    Game_Manager.turn = 0;
    Game_Manager.selected_piece = noone;
    
    show_debug_message("=== CLEAN RESTART COMPLETE ===");
    show_debug_message("You can now make your move, then AI will respond normally");
}