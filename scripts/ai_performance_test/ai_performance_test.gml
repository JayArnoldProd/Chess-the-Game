/// @function ai_performance_test()
/// @description Tests AI performance
function ai_performance_test() {
    show_debug_message("=== AI PERFORMANCE TEST ===");
    
    var start_time = current_time;
    
    // Generate moves 10 times
    for (var i = 0; i < 10; i++) {
        var moves = ai_get_legal_moves_fast(1);
        if (array_length(moves) > 0) {
            ai_pick_best_move_fast(moves);
        }
    }
    
    var total_time = current_time - start_time;
    show_debug_message("10 move calculations took: " + string(total_time) + "ms");
    show_debug_message("Average per move: " + string(total_time / 10) + "ms");
    show_debug_message("=== END PERFORMANCE TEST ===");
}