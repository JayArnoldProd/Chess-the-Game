/// @function ai_emergency_fix()
/// @description Fixes the immediate AI crash and gets system working
function ai_emergency_fix() {
    show_debug_message("=== APPLYING EMERGENCY AI FIX ===");
    
    if (!instance_exists(AI_Manager)) {
        show_debug_message("ERROR: AI_Manager not found!");
        return false;
    }
    
    with (AI_Manager) {
        // Fix the immediate crash variables
        if (!variable_instance_exists(id, "ai_selected_move")) ai_selected_move = undefined;
        if (!variable_instance_exists(id, "time_per_move_history")) time_per_move_history = [];
        if (!variable_instance_exists(id, "move_complexity_history")) move_complexity_history = [];
        if (!variable_instance_exists(id, "position_complexity")) position_complexity = 30;
        if (!variable_instance_exists(id, "time_budget")) time_budget = 1000;
        if (!variable_instance_exists(id, "use_fast_mode")) use_fast_mode = true;
        if (!variable_instance_exists(id, "time_pressure")) time_pressure = false;
        if (!variable_instance_exists(id, "search_efficiency")) search_efficiency = 1.0;
        if (!variable_instance_exists(id, "think_start_time")) think_start_time = 0;
        if (!variable_instance_exists(id, "search_cancelled")) search_cancelled = false;
        if (!variable_instance_exists(id, "enhanced_initialized")) enhanced_initialized = true;
        
        // Reset thinking state to prevent getting stuck
        if (variable_instance_exists(id, "ai_thinking")) {
            ai_thinking = false;
        }
        
        show_debug_message("✓ Emergency variables initialized");
    }
    
    show_debug_message("=== EMERGENCY FIX COMPLETE ===");
    show_debug_message("AI should now work properly!");
    return true;
}
