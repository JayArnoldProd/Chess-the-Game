/// @function ai_test_simple_move()
/// @description Tests if simple AI can make a move
function ai_test_simple_move() {
    show_debug_message("=== TESTING SIMPLE AI MOVE ===");
    
    // Initialize cleanly first
    ai_initialize_clean();
    
    // Switch to simple mode
    ai_switch_to_simple_mode();
    
    // Set to AI turn
    Game_Manager.turn = 1;
    
    show_debug_message("AI turn started in simple mode");
    show_debug_message("Watch debug display for AI status");
    
    return true;
}
