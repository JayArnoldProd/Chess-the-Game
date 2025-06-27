// F4 Key (vk_f4) - Force AI Move (for testing)
// KeyPress_vk_f4 event:
if (Game_Manager.turn != 1) {
    Game_Manager.turn = 1;
    show_debug_message("Switched to AI turn");
} else {
    if (instance_exists(AI_Manager)) {
        AI_Manager.ai_thinking = false;
        AI_Manager.ai_move_delay = 0;
        show_debug_message("Forced AI to move");
    }
}