/// @function ai_decrease_difficulty()
function ai_decrease_difficulty() {
    var current = ai_get_current_difficulty();
    ai_set_difficulty_enhanced(max(current - 1, 1));
}