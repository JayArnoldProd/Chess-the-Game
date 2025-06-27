/// @function ai_get_legal_moves_fast(color)
function ai_get_legal_moves_fast(color) {
    var moves = [];
    
    // Force update all piece moves first
    with (Chess_Piece_Obj) {
        if (instance_exists(id) && piece_type == color) {
            // Force recalculate valid moves
            event_perform(ev_step, ev_step_normal);
        }
    }
    
    // Now get moves from ALL pieces of this color
    with (Chess_Piece_Obj) {
        if (instance_exists(id) && piece_type == color) {
            // Get piece's valid moves
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
                if (target_piece != noone && target_piece != id) {
                    if (target_piece.piece_type == piece_type) {
                        continue; // Skip illegal moves
                    }
                }
                
                var is_capture = (target_piece != noone && target_piece != id && target_piece.piece_type != piece_type);
                
                // Validate knight moves specifically
                if (piece_id == "knight") {
                    var dx = abs(move[0]);
                    var dy = abs(move[1]);
                    if (!((dx == 2 && dy == 1) || (dx == 1 && dy == 2))) {
                        continue; // Skip invalid knight moves
                    }
                }
                
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
                
                array_push(moves, move_data);
            }
        }
    }
    
    // Filter out moves that put own king in check
    var safe_moves = [];
    for (var i = 0; i < array_length(moves); i++) {
        if (ai_is_move_safe(moves[i])) {
            array_push(safe_moves, moves[i]);
        }
    }
    
    return safe_moves;
}
