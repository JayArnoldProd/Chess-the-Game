/// @function ai_force_move()
/// @description Forces AI to make a move immediately

function ai_force_move() {
    show_debug_message("Forcing AI move");
    search_cancelled = true;
    ai_thinking = false;
    ai_move_delay = 0;
    
    if (best_move_so_far == undefined) {
        best_move_so_far = ai_emergency_move();
    }
}