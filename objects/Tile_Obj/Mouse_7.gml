//Tile_Obj Left Released

selected_piece = Game_Manager.selected_piece;

if (valid_move and (Game_Manager.selected_piece != noone)) {
    var piece = Game_Manager.selected_piece;
    
    if (piece.stepping_chain > 0) {
        if (piece.stepping_chain == 2) {
            // --- EXTRA MOVE PHASE 1 ---
            // Move both piece and stepping stone to the chosen tile.
            piece.x = x;
            piece.y = y;
            piece.stepping_stone_instance.x = x;
            piece.stepping_stone_instance.y = y;
            piece.stepping_chain = 1;  // Advance to phase 2
            show_debug_message("Stepping stone extra move phase 1 completed. Now choose your next move.");
            // Do not clear Game_Manager.selected_piece here.
        }
        else if (piece.stepping_chain == 1) {
            // --- EXTRA MOVE PHASE 2 ---
            // Execute the final move.
            piece.x = x;
            piece.y = y;
            // Revert the stepping stone back to its original location.
            piece.stepping_stone_instance.x = piece.stone_original_x;
            piece.stepping_stone_instance.y = piece.stone_original_y;
            // Reset extra–move state.
            piece.stepping_chain = 0;
            piece.extra_move_pending = false;
            piece.stepping_stone_instance = noone;
            show_debug_message("Stepping stone chain complete; turn ends.");
            // End the turn by deselecting the piece.
            Game_Manager.selected_piece = noone;
        }
        valid_move = false;
    }
    else {
        // --- NORMAL MOVE PROCESSING ---
        piece.x = x;
        piece.y = y;
        piece.has_moved = true;
        Game_Manager.selected_piece = noone;
        valid_move = false;
    }
}



