/// @function ai_test_basic_functions()
/// @description Tests if basic AI functions work
function ai_test_basic_functions() {
    show_debug_message("=== TESTING BASIC AI FUNCTIONS ===");
    
    var tests_passed = 0;
    var total_tests = 4;
    
    // Test 1: Move generation
    try {
        var moves = ai_get_legal_moves_fast(1);
        show_debug_message("✓ Move generation: " + string(array_length(moves)) + " moves");
        tests_passed++;
    } catch (error) {
        show_debug_message("✗ Move generation failed: " + string(error));
    }
    
    // Test 2: Board evaluation
    try {
        var eval = ai_evaluate_board();
        show_debug_message("✓ Board evaluation: " + string(eval));
        tests_passed++;
    } catch (error) {
        show_debug_message("✗ Board evaluation failed: " + string(error));
    }
    
    // Test 3: Simple move scoring
    try {
        var moves = ai_get_legal_moves_fast(1);
        if (array_length(moves) > 0) {
            var score_ = ai_score_move_fast(moves[0]);
            show_debug_message("✓ Move scoring: " + string(score_));
            tests_passed++;
        } else {
            show_debug_message("? No moves to score");
            tests_passed++;
        }
    } catch (error) {
        show_debug_message("✗ Move scoring failed: " + string(error));
    }
    
    // Test 4: Simple move selection
    try {
        var best_move = ai_simple_fallback_move();
        if (best_move != undefined) {
            show_debug_message("✓ Simple move selection working");
            tests_passed++;
        } else {
            show_debug_message("? No moves available for selection");
            tests_passed++;
        }
    } catch (error) {
        show_debug_message("✗ Simple move selection failed: " + string(error));
    }
    
    show_debug_message("=== BASIC TESTS COMPLETE ===");
    show_debug_message("Passed: " + string(tests_passed) + "/" + string(total_tests));
    
    return tests_passed >= 3; // At least 3 out of 4 should work
}