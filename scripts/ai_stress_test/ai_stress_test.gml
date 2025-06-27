/// @function ai_stress_test()
/// @description Stress tests the AI system
function ai_stress_test() {
    show_debug_message("=== AI STRESS TEST ===");
    
    var start_time = current_time;
    var moves_tested = 0;
    var errors = 0;
    
    try {
        // Test rapid move generation
        for (var i = 0; i < 100; i++) {
            var moves = ai_get_legal_moves_fast(1);
            moves_tested += array_length(moves);
            
            // Test move scoring
            for (var j = 0; j < min(5, array_length(moves)); j++) {
                var score_ = ai_score_move_fast(moves[j]);
            }
        }
        
        // Test rapid evaluation
        for (var i = 0; i < 50; i++) {
            var eval = ai_evaluate_board();
        }
        
        var total_time = current_time - start_time;
        show_debug_message("Stress test completed in " + string(total_time) + "ms");
        show_debug_message("Moves tested: " + string(moves_tested));
        show_debug_message("Errors: " + string(errors));
        
        if (total_time > 5000) {
            show_debug_message("WARNING: Performance below expected");
        }
        
    } catch (error) {
        show_debug_message("STRESS TEST FAILED: " + string(error));
        errors++;
    }
    
    show_debug_message("=== END STRESS TEST ===");
    return errors == 0;
}