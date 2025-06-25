/// @function ai_update_piece_valid_moves()
/// @description Updates valid moves for all pieces (called before AI thinks)

function ai_update_piece_valid_moves() {
    // Force update valid moves for all pieces safely
    with (Chess_Piece_Obj) {
        if (instance_exists(id)) {
            // Trigger the step event to recalculate valid moves
            if (object_index == Pawn_Obj) {
                // Pawns have complex move generation in their step event
                event_perform(ev_step, ev_step_normal);
            } else if (object_index == King_Obj) {
                // Kings need to recalculate castling
                event_perform(ev_step, ev_step_normal);
            } else if (object_index == Bishop_Obj || object_index == Queen_Obj || object_index == Rook_Obj) {
                // Sliding pieces need line-of-sight recalculation
                event_perform(ev_step, ev_step_normal);
            } else if (object_index == Knight_Obj) {
                // Knights have special stepping stone logic
                event_perform(ev_step, ev_step_normal);
            }
        }
    }
}