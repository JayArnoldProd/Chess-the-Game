/// @function ai_performance_benchmark()
/// @description Runs performance tests
function ai_performance_benchmark() {
    show_debug_message("=== AI PERFORMANCE BENCHMARK ===");
    
    var iterations = 50;
    var start_time = current_time;
    
    // Test move generation speed
    for (var i = 0; i < iterations; i++) {
        var moves = ai_get_legal_moves_fast(1);
    }
    
    var generation_time = current_time - start_time;
    show_debug_message("Move generation: " + string(generation_time / iterations) + "ms per call");
    
    // Test evaluation speed
    start_time = current_time;
    for (var i = 0; i < iterations; i++) {
        var eval = ai_evaluate_board();
    }
    
    var eval_time = current_time - start_time;
    show_debug_message("Board evaluation: " + string(eval_time / iterations) + "ms per call");
    
    // Test complete move cycle
    var legal_moves = ai_get_legal_moves_fast(1);
    if (array_length(legal_moves) > 0) {
        start_time = current_time;
        
        for (var i = 0; i < min(10, iterations); i++) {
            var best_move = ai_fast_tactical_search();
        }
        
        var search_time = current_time - start_time;
        show_debug_message("Fast tactical search: " + string(search_time / min(10, iterations)) + "ms per call");
    }
    
    show_debug_message("=== END BENCHMARK ===");
}