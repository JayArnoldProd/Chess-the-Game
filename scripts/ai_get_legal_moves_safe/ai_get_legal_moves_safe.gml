/// @function ai_get_legal_moves_safe(color)
/// @param {real} color The color to get moves for (0=white, 1=black)
/// @returns {array} Array of TRULY legal moves (filters out moves that leave king in check)
function ai_get_legal_moves_safe(color) {
    var pseudo_legal_moves = [];
    
    // Force update all piece moves first
    with (Chess_Piece_Obj) {
        if (instance_exists(id) && piece_type == color) {
            event_perform(ev_step, ev_step_normal);
        }
    }
    
    // Get pseudo-legal moves from all pieces of this color
    with (Chess_Piece_Obj) {
        if (instance_exists(id) && piece_type == color) {
            for (var i = 0; i < array_length(valid_moves); i++) {
                var move = valid_moves[i];
                var target_x = x + move[0] * Board_Manager.tile_size;
                var target_y = y + move[1] * Board_Manager.tile_size;
                
                // Check if target is on board
                var tile = instance_place(target_x, target_y, Tile_Obj);
                if (!tile) continue;
                
                // Check what's at target
                var target_piece = instance_position(target_x, target_y, Chess_Piece_Obj);
                
                // Skip moves to squares with same-color pieces
                if (target_piece != noone && target_piece != id && target_piece.piece_type == piece_type) {
                    continue;
                }
                
                var is_capture = (target_piece != noone && target_piece != id && target_piece.piece_type != piece_type);
                
                // Create move structure
                var move_data = {
                    piece: id,
                    from_x: x,
                    from_y: y,
                    to_x: target_x,
                    to_y: target_y,
                    is_capture: is_capture,
                    captured_piece: is_capture ? target_piece : noone,
                    piece_id: piece_id,
                    piece_type: piece_type
                };
                
                array_push(pseudo_legal_moves, move_data);
            }
        }
    }
    
    // CRITICAL FIX: Filter out moves that leave our king in check
    // Build virtual board for check testing
    var _vboard = ai_build_virtual_board();
    var legal_moves = [];
    
    for (var i = 0; i < array_length(pseudo_legal_moves); i++) {
        var mv = pseudo_legal_moves[i];
        
        // Convert real coordinates to board coordinates
        var from_col = round((mv.from_x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        var from_row = round((mv.from_y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        var to_col = round((mv.to_x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        var to_row = round((mv.to_y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        
        // Create virtual move
        var vmove = {
            from_col: from_col,
            from_row: from_row,
            to_col: to_col,
            to_row: to_row,
            is_capture: mv.is_capture,
            piece_id: mv.piece_id,
            piece_type: mv.piece_type
        };
        
        // Simulate the move on a copy of the board
        var test_board = ai_copy_board(_vboard);
        ai_make_move_virtual(test_board, vmove);
        
        // Check if our king is still in check after this move
        if (!ai_is_king_in_check_virtual(test_board, color)) {
            array_push(legal_moves, mv);
        } else {
            show_debug_message("ai_get_legal_moves_safe: Filtered illegal move by " + mv.piece_id + " - leaves king in check");
        }
    }
    
    show_debug_message("ai_get_legal_moves_safe: " + string(array_length(pseudo_legal_moves)) + " pseudo-legal -> " + string(array_length(legal_moves)) + " legal moves");
    
    return legal_moves;
}