/// @function ai_increase_difficulty()
function ai_increase_difficulty() {
    var current = ai_get_current_difficulty();
    ai_set_difficulty_enhanced(min(current + 1, 10));
}