/// @function ai_verify_installation()
/// @description Checks if all AI components are working correctly
function ai_verify_installation() {
    show_debug_message("=== AI INSTALLATION VERIFICATION ===");
    
    var success = true;
    var tests_passed = 0;
    var total_tests = 8;
    
    // Test 1: AI_Manager exists
    if (instance_exists(AI_Manager)) {
        show_debug_message("✓ AI_Manager exists");
        tests_passed++;
    } else {
        show_debug_message("✗ AI_Manager missing!");
        success = false;
    }
    
    // Test 2: Required variables exist
    var required_vars = ["ai_enabled", "ai_thinking", "ai_selected_move", "search_depth", "time_budget"];
    var vars_found = 0;
    for (var i = 0; i < array_length(required_vars); i++) {
        if (variable_instance_exists(AI_Manager, required_vars[i])) {
            vars_found++;
        }
    }
    
    if (vars_found == array_length(required_vars)) {
        show_debug_message("✓ All required variables initialized");
        tests_passed++;
    } else {
        show_debug_message("✗ Missing " + string(array_length(required_vars) - vars_found) + " required variables");
        success = false;
    }
    
    // Test 3: Move generation works
    try {
        var moves = ai_get_legal_moves_fast(1);
        if (is_array(moves)) {
            show_debug_message("✓ Move generation working (" + string(array_length(moves)) + " moves)");
            tests_passed++;
        } else {
            show_debug_message("✗ Move generation failed");
            success = false;
        }
    } catch (error) {
        show_debug_message("✗ Move generation error: " + string(error));
        success = false;
    }
    
    // Test 4: Board evaluation works
    try {
        var eval = ai_evaluate_board();
        if (is_real(eval)) {
            show_debug_message("✓ Board evaluation working (score: " + string(eval) + ")");
            tests_passed++;
        } else {
            show_debug_message("✗ Board evaluation failed");
            success = false;
        }
    } catch (error) {
        show_debug_message("✗ Board evaluation error: " + string(error));
        success = false;
    }
    
    // Test 5: Difficulty system works
    try {
        ai_set_difficulty_enhanced(3);
        var diff = ai_get_current_difficulty();
        if (diff == 3) {
            show_debug_message("✓ Difficulty system working");
            tests_passed++;
        } else {
            show_debug_message("✗ Difficulty system failed (set 3, got " + string(diff) + ")");
            success = false;
        }
    } catch (error) {
        show_debug_message("✗ Difficulty system error: " + string(error));
        success = false;
    }
    
    // Test 6: Fast search works
    try {
        var moves = ai_get_legal_moves_fast(1);
        if (array_length(moves) > 0) {
            var best = ai_fast_tactical_search();
            if (best != undefined) {
                show_debug_message("✓ Fast tactical search working");
                tests_passed++;
            } else {
                show_debug_message("✗ Fast tactical search returned undefined");
                success = false;
            }
        } else {
            show_debug_message("? No moves available for fast search test");
            tests_passed++; // Not a failure if no moves
        }
    } catch (error) {
        show_debug_message("✗ Fast tactical search error: " + string(error));
        success = false;
    }
    
    // Test 7: Position analysis works
    try {
        var complexity = ai_analyze_position_complexity();
        if (is_real(complexity) && complexity >= 0) {
            show_debug_message("✓ Position analysis working (complexity: " + string(complexity) + ")");
            tests_passed++;
        } else {
            show_debug_message("✗ Position analysis failed");
            success = false;
        }
    } catch (error) {
        show_debug_message("✗ Position analysis error: " + string(error));
        success = false;
    }
    
    // Test 8: Enhanced functions exist
    var enhanced_functions = ["ai_comprehensive_debug", "ai_set_difficulty_enhanced", "ai_fast_tactical_search"];
    var functions_found = 0;
    for (var i = 0; i < array_length(enhanced_functions); i++) {
        if (script_exists(asset_get_index(enhanced_functions[i]))) {
            functions_found++;
        }
    }
    
    if (functions_found == array_length(enhanced_functions)) {
        show_debug_message("✓ All enhanced functions available");
        tests_passed++;
    } else {
        show_debug_message("✗ Missing " + string(array_length(enhanced_functions) - functions_found) + " enhanced functions");
        success = false;
    }
    
    // Summary
    show_debug_message("=== VERIFICATION COMPLETE ===");
    show_debug_message("Tests Passed: " + string(tests_passed) + "/" + string(total_tests));
    
    if (success) {
        show_debug_message("🎉 ALL TESTS PASSED! AI system ready to use.");
        show_debug_message("💡 Try pressing number keys 1-9 to change difficulty!");
        return true;
    } else {
        show_debug_message("⚠️  Some tests failed. Check the errors above.");
        return false;
    }
}
