/// @function ai_move_improves_position(move) - Simplified implementation  
/// @param {struct} move The move to check
/// @returns {bool} Whether move improves position
function ai_move_improves_position(move) {
    // Simplified position improvement check
    var target_file = round((move.to_x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var target_rank = round((move.to_y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    
    // Moving to center is good
    if (target_file >= 2 && target_file <= 5 && target_rank >= 2 && target_rank <= 5) {
        return true;
    }
    
    // Developing pieces is good
    if (!move.piece.has_moved && (move.piece_id == "knight" || move.piece_id == "bishop")) {
        return true;
    }
    
    return false;
}