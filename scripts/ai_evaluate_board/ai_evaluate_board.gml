/// @function ai_evaluate_board()
/// @description Evaluates the current board position for the AI
/// @returns {real} The evaluation score_ (positive favors black, negative favors white)

function ai_evaluate_board() {
    var score_ = 0;
    var white_pieces = 0;
    var black_pieces = 0;
    var white_material = 0;
    var black_material = 0;
    
    // Count pieces and calculate material - use safer approach
    var all_pieces = [];
    with (Chess_Piece_Obj) {
        if (instance_exists(id)) {
            array_push(all_pieces, {
                piece_type: piece_type,
                piece_id: piece_id,
                x: x,
                y: y,
                has_moved: has_moved,
                object_index: object_index,
                valid_moves: valid_moves
            });
        }
    }
    
    // Process pieces safely
    for (var i = 0; i < array_length(all_pieces); i++) {
        var piece_data = all_pieces[i];
        
        if (piece_data.piece_type == 0) { // White
            white_pieces++;
            white_material += AI_Manager.piece_values[$ piece_data.piece_id];
        } else if (piece_data.piece_type == 1) { // Black
            black_pieces++;
            black_material += AI_Manager.piece_values[$ piece_data.piece_id];
        }
    }
    
    // Determine if we're in endgame (few pieces left)
    var total_pieces = white_pieces + black_pieces;
    var is_endgame = (total_pieces <= 12);
    
    // Evaluate each piece
    for (var i = 0; i < array_length(all_pieces); i++) {
        var piece_data = all_pieces[i];
        var piece_score_ = 0;
        
        // Calculate grid position safely
        var grid_x = 0;
        var grid_y = 0;
        
        if (instance_exists(Object_Manager) && instance_exists(Board_Manager)) {
            grid_x = round((piece_data.x - Object_Manager.topleft_x) / Board_Manager.tile_size);
            grid_y = round((piece_data.y - Object_Manager.topleft_y) / Board_Manager.tile_size);
            
            // Clamp coordinates to valid range
            grid_x = clamp(grid_x, 0, 7);
            grid_y = clamp(grid_y, 0, 7);
        }
        
        // Material value
        piece_score_ += AI_Manager.piece_values[$ piece_data.piece_id];
        
        // Positional value based on piece type
        var positional_value = 0;
        var table_y = (piece_data.piece_type == 0) ? grid_y : (7 - grid_y); // Flip for black
        table_y = clamp(table_y, 0, 7); // Safety clamp
        
        switch (piece_data.piece_id) {
            case "pawn":
                positional_value = AI_Manager.pawn_table[table_y][grid_x];
                break;
            case "knight":
                positional_value = AI_Manager.knight_table[table_y][grid_x];
                break;
            case "bishop":
                positional_value = AI_Manager.bishop_table[table_y][grid_x];
                break;
            case "rook":
                positional_value = AI_Manager.rook_table[table_y][grid_x];
                break;
            case "queen":
                positional_value = AI_Manager.queen_table[table_y][grid_x];
                break;
            case "king":
                if (is_endgame) {
                    positional_value = AI_Manager.king_end_table[table_y][grid_x];
                } else {
                    positional_value = AI_Manager.king_middle_table[table_y][grid_x];
                }
                break;
        }
        
        piece_score_ += positional_value;
        
        // Mobility bonus (number of valid moves) - safely handle valid_moves
        var mobility = 0;
        if (variable_struct_exists(piece_data, "valid_moves") && is_array(piece_data.valid_moves)) {
            mobility = array_length(piece_data.valid_moves);
        }
        piece_score_ += mobility * 2;
        
        // Apply score_ based on piece color
        if (piece_data.piece_type == 1) { // Black (AI)
            score_ += piece_score_;
        } else { // White (Player)
            score_ -= piece_score_;
        }
    }
    
    // Additional evaluation factors
    
    // King safety - with existence checks
    score_ += ai_evaluate_king_safety_safe(1) - ai_evaluate_king_safety_safe(0);
    
    // Pawn structure - with existence checks
    score_ += ai_evaluate_pawn_structure_safe(1) - ai_evaluate_pawn_structure_safe(0);
    
    // Control of center
    score_ += ai_evaluate_center_control_safe();
    
    return score_;
}