/// @function ai_end_stepping_stone_sequence()
/// @description Cleanly ends the stepping stone sequence
function ai_end_stepping_stone_sequence() {
    show_debug_message("AI: Ending stepping stone sequence");
    
    var piece = AI_Manager.ai_stepping_piece;
    
    if (instance_exists(piece)) {
        show_debug_message("AI: Cleaning up piece " + piece.piece_id + " at (" + string(piece.x) + "," + string(piece.y) + ")");
        
        // Return stepping stone to original position if it exists and was moved
        if (instance_exists(piece.stepping_stone_instance)) {
            var stone = piece.stepping_stone_instance;
            if (stone.x != piece.stone_original_x || stone.y != piece.stone_original_y) {
                show_debug_message("AI: Returning stone to original position");
                stone.x = piece.stone_original_x;
                stone.y = piece.stone_original_y;
                stone.is_moving = false;
            }
        }
        
        // Clean up piece stepping stone state
        piece.stepping_chain = 0;
        piece.extra_move_pending = false;
        piece.stepping_stone_instance = noone;
        piece.stepping_stone_used = true;
        piece.pending_turn_switch = undefined;
        piece.pending_normal_move = false;
        
        // Make sure piece stops moving and snaps to grid correctly
        if (piece.is_moving) {
            piece.is_moving = false;
            // Snap to grid using proper grid origin
            var grid_x = round((piece.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
            var grid_y = round((piece.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
            piece.x = Object_Manager.topleft_x + grid_x * Board_Manager.tile_size;
            piece.y = Object_Manager.topleft_y + grid_y * Board_Manager.tile_size;
            show_debug_message("AI: Snapped piece to grid at (" + string(piece.x) + "," + string(piece.y) + ")");
        }
        
        // Force piece to recalculate normal moves
        with (piece) {
            event_perform(ev_step, ev_step_normal);
        }
    }
    
    // Clean up AI manager state
    AI_Manager.ai_stepping_phase = 0;
    AI_Manager.ai_stepping_piece = noone;
    
    // Switch to player turn
    Game_Manager.turn = 0;
    Game_Manager.selected_piece = noone;
    
    show_debug_message("AI: Stepping stone sequence ended - player's turn");
}