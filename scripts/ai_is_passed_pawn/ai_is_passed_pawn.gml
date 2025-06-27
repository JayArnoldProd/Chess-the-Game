/// @function ai_is_passed_pawn(pawn_id)
/// @param {id} pawn_id The pawn to check
/// @returns {bool} Whether the pawn is passed

function ai_is_passed_pawn(pawn_id) {
    if (!instance_exists(pawn_id)) return false;
    
    var pawn = pawn_id;
    var pawn_file = round((pawn.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var pawn_rank = round((pawn.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    
    // Check for enemy pawns that can block or capture
    with (Pawn_Obj) {
        if (instance_exists(id) && piece_type != pawn.piece_type) {
            var enemy_file = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
            var enemy_rank = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
            
            // Check if enemy pawn can interfere
            if (abs(enemy_file - pawn_file) <= 1) {
                if (pawn.piece_type == 0) { // White pawn
                    if (enemy_rank > pawn_rank) return false;
                } else { // Black pawn
                    if (enemy_rank < pawn_rank) return false;
                }
            }
        }
    }
    
    return true;
}