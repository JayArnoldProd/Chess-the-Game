/// @function ai_demonstrate_difficulty()
/// @description Shows how difficulty affects AI behavior
function ai_demonstrate_difficulty() {
    show_debug_message("=== DIFFICULTY DEMONSTRATION ===");
    
    var difficulties = [1, 3, 5, 7, 10];
    var diff_names = ["Beginner", "Medium-Easy", "Medium-Hard", "Very Hard", "Grandmaster"];
    
    for (var i = 0; i < array_length(difficulties); i++) {
        var diff = difficulties[i];
        ai_set_difficulty_enhanced(diff);
        
        show_debug_message("--- " + diff_names[i] + " (Level " + string(diff) + ") ---");
        show_debug_message("Search Depth: " + string(AI_Manager.search_depth));
        show_debug_message("Max Moves Considered: " + string(AI_Manager.max_moves_to_consider));
        show_debug_message("Time Budget: " + string(AI_Manager.time_budget) + "ms");
        
        // Test move selection time
        var moves = ai_get_legal_moves_fast(1);
        if (array_length(moves) > 0) {
            var start_time = current_time;
            var best_move = ai_fast_tactical_search();
            var search_time = current_time - start_time;
            show_debug_message("Actual Search Time: " + string(search_time) + "ms");
        }
        show_debug_message("");
    }
    
    show_debug_message("=== DEMONSTRATION COMPLETE ===");
}