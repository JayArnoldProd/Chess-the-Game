// R Key - Reset Game State  
// KeyPress_82 event (Key "R"):
if (keyboard_check(vk_control)) {
    // Reset to starting position
    Game_Manager.turn = 0;
    Game_Manager.selected_piece = noone;
    ai_restart_clean();
    show_debug_message("Game state reset");
}