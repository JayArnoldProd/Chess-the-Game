/// @function ai_validate_move_legality(move)
/// @param {struct} move The move to validate
/// @returns {bool} Whether the move is actually legal
function ai_validate_move_legality(move) {
    if (!instance_exists(move.piece)) return false;
    
    var piece = move.piece;
    
    // Check basic bounds
    if (move.to_x < 0 || move.to_y < 0) return false;
    
    // Check target tile exists
    var target_tile = instance_place(move.to_x, move.to_y, Tile_Obj);
    if (!target_tile) return false;
    
    // Check for same-color piece at target
    var target_piece = instance_position(move.to_x, move.to_y, Chess_Piece_Obj);
    if (target_piece != noone && target_piece.piece_type == piece.piece_type) {
        return false; // Can't capture own piece
    }
    
    // Validate piece-specific move patterns
    switch (piece.piece_id) {
        case "knight":
            var dx = abs((move.to_x - move.from_x) / Board_Manager.tile_size);
            var dy = abs((move.to_y - move.from_y) / Board_Manager.tile_size);
            return (dx == 2 && dy == 1) || (dx == 1 && dy == 2);
            
        case "pawn":
            // Simplified pawn validation
            var forward = (piece.piece_type == 0) ? -1 : 1;
            var dy = (move.to_y - move.from_y) / Board_Manager.tile_size;
            var dx = (move.to_x - move.from_x) / Board_Manager.tile_size;
            
            if (dx == 0) { // Forward move
                return (dy == forward) || (dy == 2 * forward && !piece.has_moved);
            } else if (abs(dx) == 1 && dy == forward) { // Diagonal capture
                return target_piece != noone;
            }
            return false;
            
        // Add other piece validations as needed
    }
    
    return true; // Default to true for other pieces
}
