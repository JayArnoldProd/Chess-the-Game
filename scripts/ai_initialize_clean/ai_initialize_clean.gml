/// @function ai_initialize_clean()
/// @description Properly initializes AI system from scratch
function ai_initialize_clean() {
    show_debug_message("=== INITIALIZING AI CLEAN ===");
    
    if (!instance_exists(AI_Manager)) {
        show_debug_message("ERROR: AI_Manager not found!");
        return false;
    }
    
    with (AI_Manager) {
        // Reset all thinking variables
        ai_enabled = true;
        ai_thinking = false;
        ai_selected_move = undefined;
        ai_move_delay = 0;
        
        // Reset loop detection variables
        ai_move_count = 0;
        ai_last_turn_check = -1;
        ai_cooldown = 0;
        ai_timeout_count = 0;
        think_start_time = 0;
        
        // Reset performance variables
        last_move_time = 0;
        
        // Set default difficulty
        search_depth = 3;
        max_moves_to_consider = 10;
        
        show_debug_message("✓ AI_Manager variables reset");
    }
    
    // Reset global move history
    global.ai_last_moves = [];
    global.ai_debug_visible = true;
    
    // Ensure proper turn state
    Game_Manager.turn = 0; // Start with player turn
    Game_Manager.selected_piece = noone;
    
    // Fix any stuck pieces
    with (Chess_Piece_Obj) {
        if (is_moving) {
            is_moving = false;
            move_progress = 0;
            x = round(x / Board_Manager.tile_size) * Board_Manager.tile_size;
            y = round(y / Board_Manager.tile_size) * Board_Manager.tile_size;
        }
    }
    
    show_debug_message("✓ AI initialized cleanly");
    show_debug_message("Make your move, then AI will respond");
    return true;
}
