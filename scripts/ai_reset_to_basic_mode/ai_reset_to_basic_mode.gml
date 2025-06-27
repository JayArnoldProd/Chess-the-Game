/// @function ai_reset_to_basic_mode()
/// @description Resets AI to ultra-simple mode for debugging
function ai_reset_to_basic_mode() {
    if (!instance_exists(AI_Manager)) return;
    
    show_debug_message("Resetting AI to basic mode...");
    
    with (AI_Manager) {
        search_depth = 1;
        max_moves_to_consider = 5;
        time_budget = 500;
        use_fast_mode = true;
        ai_thinking = false;
        ai_selected_move = undefined;
        
        show_debug_message("AI reset to basic mode");
    }
}