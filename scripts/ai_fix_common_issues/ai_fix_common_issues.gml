/// @function ai_fix_common_issues()
/// @description Automatically fixes common AI issues
function ai_fix_common_issues() {
    show_debug_message("Running AI diagnostic fixes...");
    
    var fixes_applied = 0;
    
    // Fix 1: Update all piece valid moves
    with (Chess_Piece_Obj) {
        if (instance_exists(id)) {
            event_perform(ev_step, ev_step_normal);
        }
    }
    fixes_applied++;
    
    // Fix 2: Ensure AI variables are properly initialized
    if (!variable_instance_exists(AI_Manager, "ai_enabled")) {
        AI_Manager.ai_enabled = true;
        fixes_applied++;
    }
    
    if (!variable_instance_exists(AI_Manager, "search_depth")) {
        AI_Manager.search_depth = 3;
        fixes_applied++;
    }
    
    // Fix 3: Clear any stuck AI thinking state
    if (variable_instance_exists(AI_Manager, "ai_thinking") && AI_Manager.ai_thinking) {
        if (variable_instance_exists(AI_Manager, "think_start_time")) {
            if (current_time - AI_Manager.think_start_time > 10000) { // 10 seconds
                AI_Manager.ai_thinking = false;
                AI_Manager.search_cancelled = true;
                fixes_applied++;
                show_debug_message("Cleared stuck AI thinking state");
            }
        }
    }
    
    // Fix 4: Validate board state
    var piece_errors = 0;
    with (Chess_Piece_Obj) {
        if (!variable_instance_exists(id, "piece_type") || 
            !variable_instance_exists(id, "piece_id") ||
            !is_array(valid_moves)) {
            piece_errors++;
        }
    }
    
    if (piece_errors > 0) {
        show_debug_message("Found " + string(piece_errors) + " pieces with invalid data");
        fixes_applied++;
    }
    
    show_debug_message("Applied " + string(fixes_applied) + " diagnostic fixes");
    return fixes_applied;
}
