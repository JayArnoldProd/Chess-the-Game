/// @function ai_debug_current_position()
/// @description Prints debug info about current position

function ai_debug_current_position() {
    show_debug_message("=== AI DEBUG INFO ===");
    show_debug_message("Current turn: " + string(Game_Manager.turn));
    show_debug_message("AI thinking: " + string(ai_thinking));
    show_debug_message("Current depth: " + string(current_depth));
    show_debug_message("Max depth: " + string(max_depth));
    
    var legal_moves = ai_get_legal_moves(1);
    show_debug_message("Legal moves for black: " + string(array_length(legal_moves)));
    
    var eval = ai_evaluate_board();
    show_debug_message("Position evaluation: " + string(eval));
    
    show_debug_message("===================");
}
