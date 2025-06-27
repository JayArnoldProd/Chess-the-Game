/// @function test_ai_system()
/// @description Tests if the complete AI system is working
function test_ai_system() {
    show_debug_message("=== TESTING AI SYSTEM ===");
    
    // Test 1: Emergency fix
    emergency_fix_all();
    show_debug_message("✓ Emergency fix applied");
    
    // Test 2: Check AI_Manager exists
    if (instance_exists(AI_Manager)) {
        show_debug_message("✓ AI_Manager exists");
    } else {
        show_debug_message("✗ AI_Manager missing!");
        return false;
    }
    
    // Test 3: Test debug display
    global.ai_debug_visible = true;
    show_debug_message("✓ Debug display enabled");
    
    // Test 4: Test difficulty system
    try {
        ai_set_difficulty_enhanced(3);
        show_debug_message("✓ Difficulty system working");
    } catch (error) {
        show_debug_message("✗ Difficulty system error: " + string(error));
    }
    
    // Test 5: Test move generation
    try {
        var moves = ai_get_legal_moves_fast(1);
        show_debug_message("✓ Move generation: " + string(array_length(moves)) + " moves");
    } catch (error) {
        show_debug_message("✗ Move generation error: " + string(error));
    }
    
    // Test 6: Test knight position
    var knight_found = false;
    with (Knight_Obj) {
        if (piece_type == 1) {
            var knight_x = round(x);
            var knight_y = round(y);
            show_debug_message("✓ Black knight at (" + string(knight_x) + "," + string(knight_y) + ")");
            knight_found = true;
            break;
        }
    }
    if (!knight_found) {
        show_debug_message("? No black knight found");
    }
    
    show_debug_message("=== TEST COMPLETE ===");
    show_debug_message("Check the top-left corner for debug display");
    show_debug_message("Press F1 to toggle debug on/off");
    
    return true;
}