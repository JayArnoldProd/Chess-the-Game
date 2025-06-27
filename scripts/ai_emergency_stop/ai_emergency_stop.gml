/// @function ai_emergency_stop()
/// @description Immediately stops AI and fixes stuck states
function ai_emergency_stop() {
    show_debug_message("=== EMERGENCY AI STOP ===");
    
    if (!instance_exists(AI_Manager)) {
        show_debug_message("AI_Manager not found");
        return;
    }
    
    with (AI_Manager) {
        ai_thinking = false;
        ai_selected_move = undefined;
        ai_cooldown = 0;
        if (variable_instance_exists(id, "ai_move_count")) ai_move_count = 0;
        
        show_debug_message("AI thinking stopped");
    }
    
    // Force turn to white (player)
    Game_Manager.turn = 0;
    Game_Manager.selected_piece = noone;
    
    // Stop all piece animations
    with (Chess_Piece_Obj) {
        if (is_moving) {
            is_moving = false;
            x = move_target_x;
            y = move_target_y;
            // Snap to grid
            x = round(x / Board_Manager.tile_size) * Board_Manager.tile_size;
            y = round(y / Board_Manager.tile_size) * Board_Manager.tile_size;
        }
    }
    
    show_debug_message("=== EMERGENCY STOP COMPLETE ===");
    show_debug_message("Current turn: " + string(Game_Manager.turn));
}
