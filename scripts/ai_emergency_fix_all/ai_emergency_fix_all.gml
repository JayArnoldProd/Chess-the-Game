/// @function emergency_fix_all()
/// @description Ultimate fix for all AI issues - UPDATED
function emergency_fix_all() {
    show_debug_message("=== EMERGENCY FIX ALL ===");
    
    // 1. Initialize AI cleanly
    ai_initialize_clean();
    
    // 2. Switch to simple mode for reliability
    ai_switch_to_simple_mode();
    
    // 3. Set debug display
    global.ai_debug_visible = true;
    
    show_debug_message("=== EMERGENCY FIX COMPLETE ===");
    show_debug_message("AI is now in simple mode");
    show_debug_message("Make your move, then AI will respond");
}