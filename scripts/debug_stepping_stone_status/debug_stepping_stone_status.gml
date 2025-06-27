/// @function debug_stepping_stone_status()
function debug_stepping_stone_status() {
    show_debug_message("=== STEPPING STONE DEBUG ===");
    show_debug_message("Current turn: " + string(Game_Manager.turn));
    show_debug_message("Selected piece: " + (Game_Manager.selected_piece != noone ? string(Game_Manager.selected_piece.piece_id) : "none"));
    
    if (instance_exists(AI_Manager)) {
        show_debug_message("AI stepping phase: " + string(AI_Manager.ai_stepping_phase));
        show_debug_message("AI stepping piece: " + (AI_Manager.ai_stepping_piece != noone ? string(AI_Manager.ai_stepping_piece.piece_id) : "none"));
    }
    
    // Check for pieces in stepping chain
    with (Chess_Piece_Obj) {
        if (stepping_chain > 0) {
            show_debug_message("Piece " + piece_id + " (type " + string(piece_type) + ") in stepping chain: " + string(stepping_chain));
        }
    }
    
    show_debug_message("=== END DEBUG ===");
}
