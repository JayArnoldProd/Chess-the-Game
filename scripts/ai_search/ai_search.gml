/// @function ai_search(depth)
/// @param {real} depth Search depth
/// @returns {struct} Best move found, or undefined
/// @description Main entry point for AI search - builds virtual board and searches
function ai_search(depth) {
    show_debug_message("AI Search: Starting search with depth " + string(depth));
    
    // Build virtual board from current game state
    var board = ai_build_virtual_board();
    
    // Get stepping stone positions for bonus evaluation
    var stones = ai_get_stepping_stones();
    
    // Run alpha-beta search
    var result = ai_alphabeta(board, depth, -999999, 999999, true, stones);
    
    show_debug_message("AI Search: Best score = " + string(result.score));
    
    if (result.move == undefined) {
        show_debug_message("AI Search: No move found!");
        return undefined;
    }
    
    // Convert virtual move back to real move format
    var best_move = ai_convert_virtual_move_to_real(result.move);
    
    return best_move;
}

/// @function ai_get_stepping_stones()
/// @returns {array} Array of stepping stone positions [[col, row], ...]
function ai_get_stepping_stones() {
    var stones = [];
    
    with (Stepping_Stone_Obj) {
        if (instance_exists(id)) {
            var col = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
            var row = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
            array_push(stones, [col, row]);
        }
    }
    
    return stones;
}

/// @function ai_convert_virtual_move_to_real(vmove)
/// @param {struct} vmove Virtual move from search
/// @returns {struct} Real move format for execution
function ai_convert_virtual_move_to_real(vmove) {
    // Find the piece at the from position
    var from_x = Object_Manager.topleft_x + vmove.from_col * Board_Manager.tile_size;
    var from_y = Object_Manager.topleft_y + vmove.from_row * Board_Manager.tile_size;
    var to_x = Object_Manager.topleft_x + vmove.to_col * Board_Manager.tile_size;
    var to_y = Object_Manager.topleft_y + vmove.to_row * Board_Manager.tile_size;
    
    // Find the piece at the source square
    var piece = noone;
    with (Chess_Piece_Obj) {
        if (point_distance(x, y, from_x, from_y) < Board_Manager.tile_size / 2) {
            piece = id;
            break;
        }
    }
    
    if (piece == noone) {
        show_debug_message("AI Search: Could not find piece at (" + string(from_x) + "," + string(from_y) + ")");
        return undefined;
    }
    
    // Find captured piece if any
    var captured = noone;
    if (vmove.is_capture) {
        with (Chess_Piece_Obj) {
            if (id != piece && point_distance(x, y, to_x, to_y) < Board_Manager.tile_size / 2) {
                captured = id;
                break;
            }
        }
    }
    
    // Check for special moves
    var special = variable_struct_exists(vmove, "special") ? vmove.special : "";
    
    return {
        piece: piece,
        from_x: from_x,
        from_y: from_y,
        to_x: to_x,
        to_y: to_y,
        is_capture: vmove.is_capture,
        captured_piece: captured,
        piece_id: vmove.piece_id,
        piece_type: vmove.piece_type,
        special: special
    };
}
