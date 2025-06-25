/// @function ai_generate_piece_moves(piece_id)
/// @param {id} piece_id The piece to generate moves for
/// @returns {array} Array of move structures for this piece

function ai_generate_piece_moves(piece_id) {
    var moves = [];
    var piece = piece_id;
    
    if (!instance_exists(piece)) return moves;
    
    // Store piece data instead of instance reference
    var piece_data = {
        x: piece.x,
        y: piece.y,
        piece_type: piece.piece_type,
        piece_id: piece.piece_id,
        has_moved: piece.has_moved,
        object_index: piece.object_index
    };
    
    // Generate normal moves
    for (var i = 0; i < array_length(piece.valid_moves); i++) {
        var move = piece.valid_moves[i];
        var target_x = piece.x + move[0] * Board_Manager.tile_size;
        var target_y = piece.y + move[1] * Board_Manager.tile_size;
        
        // Check if target is on board
        var tile = instance_place(target_x, target_y, Tile_Obj);
        if (!tile) continue;
        
        var captured_piece = instance_position(target_x, target_y, Chess_Piece_Obj);
        var captured_data = noone;
        var is_capture = false;
        
        if (captured_piece != noone && captured_piece != piece && captured_piece.piece_type != piece.piece_type) {
            is_capture = true;
            captured_data = {
                x: captured_piece.x,
                y: captured_piece.y,
                piece_type: captured_piece.piece_type,
                piece_id: captured_piece.piece_id,
                object_index: captured_piece.object_index
            };
        }
        
        // Check for en passant
        var is_en_passant = false;
        if (piece.piece_id == "pawn" && array_length(move) >= 3 && move[2] == "en_passant") {
            is_en_passant = true;
            is_capture = true;
        }
        
        // Create move structure with piece data instead of instance
        var move_struct = {
            piece_data: piece_data,
            from_x: piece.x,
            from_y: piece.y,
            to_x: target_x,
            to_y: target_y,
            captured_data: captured_data,
            is_capture: is_capture,
            is_en_passant: is_en_passant,
            is_castling: false,
            move_type: "normal"
        };
        
        array_push(moves, move_struct);
    }
    
    // Generate castling moves for kings
    if (piece.object_index == King_Obj && !piece.has_moved) {
        if (variable_instance_exists(piece, "castle_moves")) {
            for (var i = 0; i < array_length(piece.castle_moves); i++) {
                var castle_move = piece.castle_moves[i];
                var target_x = piece.x + castle_move[0] * Board_Manager.tile_size;
                var target_y = piece.y;
                
                // Find rook data
                var rook_data = noone;
                with (Rook_Obj) {
                    if (id == castle_move[3]) {
                        rook_data = {
                            x: x,
                            y: y,
                            piece_type: piece_type,
                            piece_id: piece_id,
                            has_moved: has_moved,
                            object_index: object_index
                        };
                        break;
                    }
                }
                
                var move_struct = {
                    piece_data: piece_data,
                    from_x: piece.x,
                    from_y: piece.y,
                    to_x: target_x,
                    to_y: target_y,
                    captured_data: noone,
                    is_capture: false,
                    is_en_passant: false,
                    is_castling: true,
                    rook_data: rook_data,
                    castle_direction: castle_move[0],
                    move_type: "castle"
                };
                
                array_push(moves, move_struct);
            }
        }
    }
    
    return moves;
}