// -------------------------
// Pawn_Obj Step Event
// -------------------------
switch (piece_type) {
    case 0: // White pawn
        // Promote if reached the top row.
        if (y == Top_Row.y) {
            var temp = piece_type;
            instance_change(Queen_Obj, 1);
            piece_type = temp;
        }
        
        // Clear any previous moves.
        valid_moves = [];
        
        // Forward moves: one square if empty.
        if (instance_position(x, y - Board_Manager.tile_size, Chess_Piece_Obj) == noone) {
            array_push(valid_moves, [0, -1]);
            
            // Two-square move: only if pawn hasn't moved and both squares are empty.
            if (has_moved == false) {
                if (instance_position(x, y - 2 * Board_Manager.tile_size, Chess_Piece_Obj) == noone) {
                    array_push(valid_moves, [0, -2]);
                }
            }
        }
        
        // Diagonal captures.
        var diagLeft = instance_position(x - Board_Manager.tile_size, y - Board_Manager.tile_size, Chess_Piece_Obj);
        if (diagLeft != noone && diagLeft.piece_type != 0) {
            array_push(valid_moves, [-1, -1]);
        }
        var diagRight = instance_position(x + Board_Manager.tile_size, y - Board_Manager.tile_size, Chess_Piece_Obj);
        if (diagRight != noone && diagRight.piece_type != 0) {
            array_push(valid_moves, [1, -1]);
        }
        
        // En passant for White:
        if (Game_Manager.en_passant_target_x != -1) {
            // The target must be exactly one tile away horizontally and one tile above.
            if (abs(x - Game_Manager.en_passant_target_x) == Board_Manager.tile_size &&
                (y - Game_Manager.en_passant_target_y) == Board_Manager.tile_size) {
                var dx = (Game_Manager.en_passant_target_x - x) / Board_Manager.tile_size; // ±1
                var dy = (Game_Manager.en_passant_target_y - y) / Board_Manager.tile_size; // should be -1
                array_push(valid_moves, [dx, dy, "en_passant"]);
            }
        }
        break;
        
    case 1: // Black pawn
        // Promote if reached the bottom row.
        if (y == Bottom_Row.y) {
            var temp = piece_type;
            instance_change(Queen_Obj, 1);
            piece_type = temp;
        }
        
        valid_moves = [];
        
        // Forward moves for black (downward).
        if (instance_position(x, y + Board_Manager.tile_size, Chess_Piece_Obj) == noone) {
            array_push(valid_moves, [0, 1]);
            if (has_moved == false) {
                if (instance_position(x, y + 2 * Board_Manager.tile_size, Chess_Piece_Obj) == noone) {
                    array_push(valid_moves, [0, 2]);
                }
            }
        }
        
        // Diagonal captures.
        var diagLeft_b = instance_position(x - Board_Manager.tile_size, y + Board_Manager.tile_size, Chess_Piece_Obj);
        if (diagLeft_b != noone && diagLeft_b.piece_type != 1) {
            array_push(valid_moves, [-1, 1]);
        }
        var diagRight_b = instance_position(x + Board_Manager.tile_size, y + Board_Manager.tile_size, Chess_Piece_Obj);
        if (diagRight_b != noone && diagRight_b.piece_type != 1) {
            array_push(valid_moves, [1, 1]);
        }
        
        // En passant for Black:
        if (Game_Manager.en_passant_target_x != -1) {
            // For black, the target must be one tile away horizontally and one tile below.
            if (abs(x - Game_Manager.en_passant_target_x) == Board_Manager.tile_size &&
                (Game_Manager.en_passant_target_y - y) == Board_Manager.tile_size) {
                var dx = (Game_Manager.en_passant_target_x - x) / Board_Manager.tile_size; // ±1
                var dy = (Game_Manager.en_passant_target_y - y) / Board_Manager.tile_size; // should be 1
                array_push(valid_moves, [dx, dy, "en_passant"]);
            }
        }
        break;
}
event_inherited();