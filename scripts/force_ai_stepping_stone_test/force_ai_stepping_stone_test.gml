/// @function force_ai_stepping_stone_test()
/// @description Forces AI to look for stepping stone moves
function force_ai_stepping_stone_test() {
    show_debug_message("=== FORCING AI STEPPING STONE TEST ===");
    
    if (Game_Manager.turn != 1) {
        Game_Manager.turn = 1;
        show_debug_message("Switched to AI turn");
    }
    
    debug_stepping_stones();
    
    // Get AI moves and check for stepping stones
    var moves = ai_get_legal_moves_safe(1);
    show_debug_message("AI has " + string(array_length(moves)) + " legal moves");
    
    var stepping_moves = 0;
    for (var i = 0; i < array_length(moves); i++) {
        var move = moves[i];
        var on_stone = instance_position(move.to_x + Board_Manager.tile_size/4, move.to_y + Board_Manager.tile_size/4, Stepping_Stone_Obj);
        if (on_stone) {
            stepping_moves++;
            show_debug_message("STEPPING STONE MOVE FOUND: " + move.piece_id + " to (" + string(move.to_x) + "," + string(move.to_y) + ")");
        }
    }
    
    if (stepping_moves == 0) {
        show_debug_message("No stepping stone moves available for AI");
    } else {
        show_debug_message("AI has " + string(stepping_moves) + " stepping stone moves available!");
    }
}