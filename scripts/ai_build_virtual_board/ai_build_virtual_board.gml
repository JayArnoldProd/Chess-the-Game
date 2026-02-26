/// @function ai_build_virtual_board()
/// @returns {array} 8x8 virtual board representation
/// @description Creates a lightweight board state from current piece positions
function ai_build_virtual_board() {
    // Initialize empty 8x8 board
    var board = array_create(8);
    for (var row = 0; row < 8; row++) {
        board[row] = array_create(8, noone);
    }
    
    // Populate from actual pieces
    with (Chess_Piece_Obj) {
        if (!instance_exists(id)) continue;
        
        // Calculate board coordinates
        var bx = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        var by = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        
        // Verify within bounds
        if (bx >= 0 && bx < 8 && by >= 0 && by < 8) {
            board[by][bx] = {
                piece_id: piece_id,
                piece_type: piece_type,
                has_moved: has_moved,
                instance: id
            };
        }
    }
    
    return board;
}
