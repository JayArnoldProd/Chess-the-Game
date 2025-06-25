/// @function ai_restore_game_state(state)
/// @param {struct} state The game state to restore
/// @description Restores a previously saved game state

function ai_restore_game_state(state) {
    // Destroy all current pieces
    with (Chess_Piece_Obj) {
        instance_destroy();
    }
    
    // Recreate pieces from saved state
    for (var i = 0; i < array_length(state.pieces); i++) {
        var piece_data = state.pieces[i];
        var piece = instance_create_depth(piece_data.x, piece_data.y, -1, piece_data.object_type);
        piece.piece_id = piece_data.piece_id;
        piece.piece_type = piece_data.piece_type;
        piece.has_moved = piece_data.has_moved;
        if (variable_instance_exists(piece, "en_passant_vulnerable")) {
            piece.en_passant_vulnerable = piece_data.en_passant_vulnerable;
        }
    }
    
    // Restore game manager state
    Game_Manager.turn = state.turn;
    Game_Manager.en_passant_target_x = state.en_passant_target_x;
    Game_Manager.en_passant_target_y = state.en_passant_target_y;
    
    // Find en passant pawn if it exists
    Game_Manager.en_passant_pawn = noone;
    if (state.en_passant_pawn != noone) {
        with (Pawn_Obj) {
            if (variable_instance_exists(id, "en_passant_vulnerable") && en_passant_vulnerable) {
                Game_Manager.en_passant_pawn = id;
                break;
            }
        }
    }
}
