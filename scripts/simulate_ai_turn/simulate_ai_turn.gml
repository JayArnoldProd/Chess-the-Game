/// @function simulate_ai_turn()
/// @description Forces AI to take a turn for testing
function simulate_ai_turn() {
    show_debug_message("=== SIMULATING AI TURN ===");
    
    // Ensure all pieces are stopped
    with (Chess_Piece_Obj) {
        if (is_moving) {
            is_moving = false;
            x = round(x / Board_Manager.tile_size) * Board_Manager.tile_size;
            y = round(y / Board_Manager.tile_size) * Board_Manager.tile_size;
        }
    }
    
    // Set to AI turn
    Game_Manager.turn = 1;
    
    // Reset AI state
    if (instance_exists(AI_Manager)) {
        with (AI_Manager) {
            ai_thinking = false;
            ai_selected_move = undefined;
            ai_move_delay = 0;
            ai_cooldown = 0;
        }
    }
    
    show_debug_message("AI turn started - watch for move in debug display");
    show_debug_message("If AI gets stuck, press ESC to stop it");
}