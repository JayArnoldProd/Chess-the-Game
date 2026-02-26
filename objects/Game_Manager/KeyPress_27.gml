// In Game_Manager KeyPress event for Escape key:

// Close settings menu if open
if (settings_open) {
    settings_open = false;
    exit;
}

if (Game_Manager.selected_piece != noone) {
    var piece = Game_Manager.selected_piece;
    if (piece.stepping_chain > 0) {
        // Revert the piece to its original turn position
        piece.x = piece.original_turn_x;
        piece.y = piece.original_turn_y;
        // Restore the original has_moved flag
        piece.has_moved = piece.original_has_moved;
        // Revert the stepping stone (if it exists) to its original location
        if (instance_exists(piece.stepping_stone_instance)) {
            piece.stepping_stone_instance.x = piece.stone_original_x;
            piece.stepping_stone_instance.y = piece.stone_original_y;
        }
        // Clear the extra–move state
        piece.stepping_chain = 0;
        piece.extra_move_pending = false;
        piece.stepping_stone_instance = noone;
        
        // Set the cancellation flag so that any pending tile click is ignored.
        Game_Manager.moveCancelled = true;
        
        // Deselect the piece
        Game_Manager.selected_piece = noone;
        show_debug_message("Stepping stone sequence aborted; piece reverted to original turn position.");
    }
}