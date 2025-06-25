/// @function ai_save_game_state()
/// @description Saves the current game state for minimax search
/// @returns {struct} The saved game state

function ai_save_game_state() {
    var state = {
        pieces: [],
        turn: Game_Manager.turn,
        en_passant_target_x: Game_Manager.en_passant_target_x,
        en_passant_target_y: Game_Manager.en_passant_target_y,
        en_passant_pawn: Game_Manager.en_passant_pawn
    };
    
    // Save all piece positions and states
    with (Chess_Piece_Obj) {
        var piece_data = {
            object_type: object_index,
            piece_id: piece_id,
            piece_type: piece_type,
            x: x,
            y: y,
            has_moved: has_moved,
            en_passant_vulnerable: (variable_instance_exists(id, "en_passant_vulnerable") ? en_passant_vulnerable : false)
        };
        array_push(state.pieces, piece_data);
    }
    
    return state;
}