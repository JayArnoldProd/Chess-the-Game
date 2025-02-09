//Pawn_Obj Step
switch (piece_type) {
    case 0: // White pawn
        // Promote if reached the top row.
        if (y == Top_Row.y) {
            var type = piece_type;
            instance_change(Queen_Obj, 1);
            piece_type = type;
        }
        
        // Clear any previous moves.
        valid_moves = [];
        
        // Determine forward moves:
        // Forward one square: only if that square is empty.
        if (instance_position(x, y - Board_Manager.tile_size, Chess_Piece_Obj) == noone) {
            // If the square ahead is empty, add the one-step move.
            array_push(valid_moves, [0, -1]);
            
            // Two-square move is allowed only if pawn has not moved and if both squares are empty.
            if (has_moved == false) {
                if (instance_position(x, y - 2 * Board_Manager.tile_size, Chess_Piece_Obj) == noone) {
                    array_push(valid_moves, [0, -2]);
                }
            }
        }
        
        // Check diagonal capture moves:
        // Upper left diagonal:
        var diagLeft = instance_position(x - Board_Manager.tile_size, y - Board_Manager.tile_size, Chess_Piece_Obj);
        if (diagLeft != noone) {
            if (diagLeft.piece_type != 0) { // enemy piece present
                array_push(valid_moves, [-1, -1]);
            }
        }
        // Upper right diagonal:
        var diagRight = instance_position(x + Board_Manager.tile_size, y - Board_Manager.tile_size, Chess_Piece_Obj);
        if (diagRight != noone) {
            if (diagRight.piece_type != 0) { // enemy piece present
                array_push(valid_moves, [1, -1]);
            }
        }
        break;
        
    case 1: // Black pawn
        // Promote if reached the bottom row.
        if (y == Bottom_Row.y) {
            var type = piece_type;
            instance_change(Queen_Obj, 1);
            piece_type = type;
        }
        
        valid_moves = [];
        
        // Determine forward moves for black (moving downward):
        if (instance_position(x, y + Board_Manager.tile_size, Chess_Piece_Obj) == noone) {
            array_push(valid_moves, [0, 1]);
            if (has_moved == false) {
                if (instance_position(x, y + 2 * Board_Manager.tile_size, Chess_Piece_Obj) == noone) {
                    array_push(valid_moves, [0, 2]);
                }
            }
        }
        
        // Check diagonal capture moves:
        // Lower left:
        var diagLeft_b = instance_position(x - Board_Manager.tile_size, y + Board_Manager.tile_size, Chess_Piece_Obj);
        if (diagLeft_b != noone) {
            if (diagLeft_b.piece_type != 1) { // enemy piece present
                array_push(valid_moves, [-1, 1]);
            }
        }
        // Lower right:
        var diagRight_b = instance_position(x + Board_Manager.tile_size, y + Board_Manager.tile_size, Chess_Piece_Obj);
        if (diagRight_b != noone) {
            if (diagRight_b.piece_type != 1) { // enemy piece present
                array_push(valid_moves, [1, 1]);
            }
        }
        break;
}
event_inherited();