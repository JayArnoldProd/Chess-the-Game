/// @function quick_start_ai()
/// @description Gets AI working immediately
function quick_start_ai() {
    show_debug_message("=== QUICK START AI ===");
    
    // Step 1: Clean initialization
    ai_initialize_clean();
    
    // Step 2: Set reasonable difficulty
    ai_set_difficulty_enhanced(3);
    
    // Step 3: Enable debug
    global.ai_debug_visible = true;
    
    // Step 4: Ensure player turn
    Game_Manager.turn = 0;
    
    show_debug_message("✓ AI ready to play");
    show_debug_message("✓ Make your move and AI will respond");
    show_debug_message("✓ Use Ctrl+1-5 to change difficulty");
    show_debug_message("✓ Use ESC if AI gets stuck");
    
    return true;
}