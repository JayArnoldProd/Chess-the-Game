/// @function ai_get_positional_bonus(piece_id)
/// @param {id} piece_id The piece to evaluate
/// @returns {real} Positional bonus score

function ai_get_positional_bonus(piece_id) {
    if (!instance_exists(piece_id)) return 0;
    
    var piece = piece_id;
    var bonus = 0;
    
    // Basic piece-square table values would go here
    // This is simplified for brevity
    
    var grid_x = round((piece.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var grid_y = round((piece.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
    
    grid_x = clamp(grid_x, 0, 7);
    grid_y = clamp(grid_y, 0, 7);
    
    switch (piece.piece_id) {
        case "pawn":
            // Encourage pawn advancement
            if (piece.piece_type == 0) { // White
                bonus = (7 - grid_y) * 5;
            } else { // Black
                bonus = grid_y * 5;
            }
            break;
            
        case "knight":
            // Knights better in center
            var center_distance = abs(grid_x - 3.5) + abs(grid_y - 3.5);
            bonus = (7 - center_distance) * 5;
            break;
            
        case "bishop":
            // Bishops like long diagonals
            bonus = 10;
            break;
            
        case "rook":
            // Rooks like open files
            bonus = 5;
            break;
            
        case "queen":
            // Queen likes centralization
            var center_distance = abs(grid_x - 3.5) + abs(grid_y - 3.5);
            bonus = (7 - center_distance) * 3;
            break;
            
        case "king":
            // King safety in opening/middlegame, activity in endgame
            var total_pieces = instance_number(Chess_Piece_Obj);
            if (total_pieces > 12) {
                // Middlegame - stay safe
                if (grid_y == 0 || grid_y == 7) bonus = 20;
            } else {
                // Endgame - be active
                var center_distance = abs(grid_x - 3.5) + abs(grid_y - 3.5);
                bonus = (7 - center_distance) * 8;
            }
            break;
    }
    
    return bonus;
}