/// @function ai_switch_to_simple_mode()
/// @description Switches AI to simple mode if robust mode fails
function ai_switch_to_simple_mode() {
    show_debug_message("=== SWITCHING TO SIMPLE AI MODE ===");
    
    if (!instance_exists(AI_Manager)) return;
    
    with (AI_Manager) {
        // Mark that we're using simple mode
        ai_simple_mode = true;
        
        // Reset all variables
        ai_thinking = false;
        ai_selected_move = undefined;
        ai_move_delay = 0;
        ai_move_count = 0;
        ai_cooldown = 0;
        
        show_debug_message("✓ Simple mode activated");
    }
    
    // Clear any stuck state
    Game_Manager.turn = 0;
    global.ai_last_moves = [];
    
    show_debug_message("AI will now use simple but reliable mode");
}
