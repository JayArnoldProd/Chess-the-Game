/// restore_normal_moves(piece)
/// @param piece The chess piece instance whose moveset should be restored.

function restore_normal_moves(piece) {
    // Check if the piece is a Knight (or a descendant of Knight_Obj)
    if (object_is_ancestor(piece.object_index, Knight_Obj)) {
        piece.valid_moves = [[1,-2],[1,2],[-1,-2],[-1,2],[2,-1],[2,1],[-2,-1],[-2,1]];
    }
    // If you have additional cases for other pieces, add them here.
}
