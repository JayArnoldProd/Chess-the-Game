/// @function ai_force_move_now()
/// @description Forces AI to move immediately
function ai_force_move_now() {
    if (!instance_exists(AI_Manager)) return;
    
    show_debug_message("Forcing AI move...");
    AI_Manager.ai_thinking = false;
    AI_Manager.ai_move_delay = 0;
    
    if (Game_Manager.turn != 1) {
        Game_Manager.turn = 1;
        show_debug_message("Switched to black's turn");
    }
}
