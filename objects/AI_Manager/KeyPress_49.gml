// Ctrl+1 (check keyboard_check(vk_control) in each)
// KeyPress_49 event (Key "1"):
if (keyboard_check(vk_control)) {
    ai_set_difficulty_enhanced(1);
    show_debug_message("Difficulty set to 1 (Beginner)");
}