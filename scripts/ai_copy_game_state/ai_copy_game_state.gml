/// @function ai_copy_game_state(state)
/// @param {struct} state The state to copy
/// @returns {struct} A copy of the game state

function ai_copy_game_state(state) {
    var copy = {
        pieces: [],
        turn: state.turn,
        en_passant_target_x: state.en_passant_target_x,
        en_passant_target_y: state.en_passant_target_y,
        en_passant_pawn: state.en_passant_pawn
    };
    
    for (var i = 0; i < array_length(state.pieces); i++) {
        var piece_copy = {
            object_type: state.pieces[i].object_type,
            piece_id: state.pieces[i].piece_id,
            piece_type: state.pieces[i].piece_type,
            x: state.pieces[i].x,
            y: state.pieces[i].y,
            has_moved: state.pieces[i].has_moved,
            en_passant_vulnerable: state.pieces[i].en_passant_vulnerable,
            instance_id: state.pieces[i].instance_id
        };
        array_push(copy.pieces, piece_copy);
    }
    
    return copy;
}