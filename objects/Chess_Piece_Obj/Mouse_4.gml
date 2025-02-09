// Chess_Piece_Obj Left Pressed

// Only allow selection if its the players turn
if (piece_type == 0 && Game_Manager.turn != 0) {
    exit; // It's not white's turn.
}
if (piece_type == 1 && Game_Manager.turn != 1) {
    exit; // It's not black's turn.
}

// If no piece is selected yet, record the original turn position and has_moved flag.
if (Game_Manager.selected_piece == noone) {
    original_turn_x = x;
    original_turn_y = y;
    original_has_moved = has_moved;
}

// If another piece is already selected and that piece is in an extra–move chain,
// cancel its extra–move sequence before selecting this one (see next section).
if (Game_Manager.selected_piece != noone && Game_Manager.selected_piece != self) {
    var prev_piece = Game_Manager.selected_piece;
    if (prev_piece.stepping_chain > 0) {
        // Cancel the extra–move chain on the previously selected piece.
        prev_piece.x = prev_piece.original_turn_x;
        prev_piece.y = prev_piece.original_turn_y;
        prev_piece.has_moved = prev_piece.original_has_moved;
        if (instance_exists(prev_piece.stepping_stone_instance)) {
            prev_piece.stepping_stone_instance.x = prev_piece.stone_original_x;
            prev_piece.stepping_stone_instance.y = prev_piece.stone_original_y;
        }
        prev_piece.stepping_chain = 0;
        prev_piece.extra_move_pending = false;
        prev_piece.stepping_stone_instance = noone;
        show_debug_message("Extra–move chain canceled; previous piece reverted.");
        
        // Set the cancellation flag
        Game_Manager.moveCancelled = true;
    }
}

// Play selection sound when a piece is selected
if (Game_Manager.selected_piece != self) {
	audio_play_sound_on(audio_emitter,Piece_Selection_SFX, 0, false);
}

// Now, select this piece (even if switching pieces, you'll cancel the other one first):
Game_Manager.selected_piece = self;

