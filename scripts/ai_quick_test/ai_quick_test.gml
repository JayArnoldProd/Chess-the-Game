/// @function ai_quick_test()
/// @description Quick test to verify AI is working
function ai_quick_test() {
    show_debug_message("=== QUICK AI TEST ===");
    
    if (!instance_exists(AI_Manager)) {
        show_debug_message("ERROR: AI_Manager not found!");
        return false;
    }
    
    // Test different difficulties
    for (var diff = 1; diff <= 5; diff++) {
        ai_set_difficulty_enhanced(diff);
        
        var moves = ai_get_legal_moves_fast(1);
        if (array_length(moves) > 0) {
            var start_time = current_time;
            var best_move = ai_fast_tactical_search();
            var search_time = current_time - start_time;
            
            show_debug_message("Difficulty " + string(diff) + ": " + 
                             string(array_length(moves)) + " moves, " +
                             string(search_time) + "ms search time");
        }
    }
    
    show_debug_message("=== QUICK TEST COMPLETE ===");
    return true;
}