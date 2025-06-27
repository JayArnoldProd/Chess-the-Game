/// @function quick_difficulty_test()
/// @description Tests all difficulty levels quickly
function quick_difficulty_test() {
    show_debug_message("=== DIFFICULTY TEST ===");
    
    for (var i = 1; i <= 5; i++) {
        ai_set_difficulty_enhanced(i);
        show_debug_message("Level " + string(i) + ": depth=" + string(AI_Manager.search_depth) + 
                          " moves=" + string(AI_Manager.max_moves_to_consider));
    }
    
    ai_set_difficulty_enhanced(3); // Reset to medium
    show_debug_message("Reset to level 3");
}
