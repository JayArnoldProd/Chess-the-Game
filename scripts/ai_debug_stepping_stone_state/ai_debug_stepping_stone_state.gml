/// @function ai_debug_stepping_stone_state()
/// @description Shows detailed stepping stone state
function ai_debug_stepping_stone_state() {
    show_debug_message("=== STEPPING STONE STATE DEBUG ===");
    
    if (!instance_exists(AI_Manager)) {
        show_debug_message("AI_Manager not found");
        return;
    }
    
    show_debug_message("AI stepping phase: " + string(AI_Manager.ai_stepping_phase));
    show_debug_message("AI stepping piece: " + (AI_Manager.ai_stepping_piece != noone ? string(AI_Manager.ai_stepping_piece.piece_id) : "none"));
    
    if (AI_Manager.ai_stepping_piece != noone && instance_exists(AI_Manager.ai_stepping_piece)) {
        var piece = AI_Manager.ai_stepping_piece;
        show_debug_message("Piece position: (" + string(piece.x) + "," + string(piece.y) + ")");
        show_debug_message("Piece moving: " + string(piece.is_moving));
        show_debug_message("Stepping chain: " + string(piece.stepping_chain));
        show_debug_message("Extra move pending: " + string(piece.extra_move_pending));
        
        if (instance_exists(piece.stepping_stone_instance)) {
            var stone = piece.stepping_stone_instance;
            show_debug_message("Associated stone at: (" + string(stone.x) + "," + string(stone.y) + ")");
            show_debug_message("Stone moving: " + string(stone.is_moving));
            show_debug_message("Stone original pos: (" + string(piece.stone_original_x) + "," + string(piece.stone_original_y) + ")");
        }
    }
    
    // Check all pieces in stepping chains
    var pieces_in_chain = 0;
    with (Chess_Piece_Obj) {
        if (stepping_chain > 0) {
            pieces_in_chain++;
            show_debug_message("Piece " + piece_id + " (type " + string(piece_type) + ") in stepping chain: " + string(stepping_chain));
        }
    }
    
    if (pieces_in_chain == 0) {
        show_debug_message("No pieces currently in stepping chains");
    }
    
    show_debug_message("=== END STATE DEBUG ===");
}