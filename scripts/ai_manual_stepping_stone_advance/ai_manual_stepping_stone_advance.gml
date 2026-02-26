/// @function ai_manual_stepping_stone_advance()
/// @description Manually advances stepping stone phase for testing
function ai_manual_stepping_stone_advance() {
    if (!instance_exists(AI_Manager)) return;
    
    show_debug_message("=== MANUAL STEPPING STONE ADVANCE ===");
    show_debug_message("Current AI phase: " + string(AI_Manager.ai_stepping_phase));
    
    // Check if any piece is in a stepping stone chain
    var piece_in_chain = noone;
    with (Chess_Piece_Obj) {
        if (piece_type == 1 && stepping_chain > 0) { // Black AI piece in stepping chain
            piece_in_chain = id;
            show_debug_message("Found piece in stepping chain: " + piece_id + " (chain: " + string(stepping_chain) + ")");
            break;
        }
    }
    
    if (piece_in_chain != noone && AI_Manager.ai_stepping_phase == 0) {
        // Piece is in stepping chain but AI manager doesn't know about it
        show_debug_message("Syncing AI manager with stepping stone piece");
        AI_Manager.ai_stepping_piece = piece_in_chain;
        
        if (piece_in_chain.stepping_chain == 2) {
            AI_Manager.ai_stepping_phase = 1; // Phase 1 (8-directional)
            show_debug_message("Set AI to phase 1");
        } else if (piece_in_chain.stepping_chain == 1) {
            AI_Manager.ai_stepping_phase = 2; // Phase 2 (normal moves)
            show_debug_message("Set AI to phase 2");
        }
    }
    
    if (AI_Manager.ai_stepping_phase == 0) {
        show_debug_message("No stepping stone sequence active");
        return;
    }
    
    var piece = AI_Manager.ai_stepping_piece;
    if (!instance_exists(piece)) {
        show_debug_message("No stepping stone piece found, clearing phase");
        AI_Manager.ai_stepping_phase = 0;
        return;
    }
    
    show_debug_message("Stepping piece: " + piece.piece_id + " at (" + string(piece.x) + "," + string(piece.y) + ")");
    show_debug_message("Piece stepping_chain: " + string(piece.stepping_chain));
    
    // Stop any current animations
    with (Chess_Piece_Obj) {
        if (is_moving) {
            is_moving = false;
            x = move_target_x;
            y = move_target_y;
        }
    }
    with (Stepping_Stone_Obj) {
        if (is_moving) {
            is_moving = false;
            x = move_target_x;
            y = move_target_y;
        }
    }
    
    // Force advancement or execution
    show_debug_message("Triggering stepping stone handler...");
    ai_handle_stepping_stone_move();
}