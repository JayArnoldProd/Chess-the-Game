/// @function ai_execute_move_fast_robust(move)
/// @param {struct} move The move to execute
/// @description FINAL FIX for knight loop issue

function ai_execute_move_fast_robust(move) {
    if (move == undefined || !instance_exists(move.piece)) {
        show_debug_message("AI Error: Invalid move or piece");
        Game_Manager.turn = 0;
        return false;
    }
    
    var piece = move.piece;
    
    // CRITICAL: Stop all animations first
    with (Chess_Piece_Obj) {
        if (is_moving) {
            is_moving = false;
            move_progress = 0;
            x = round(x / Board_Manager.tile_size) * Board_Manager.tile_size;
            y = round(y / Board_Manager.tile_size) * Board_Manager.tile_size;
        }
    }
    
    // CRITICAL: Snap piece to exact grid position
    var grid_from_x = round(piece.x / Board_Manager.tile_size) * Board_Manager.tile_size;
    var grid_from_y = round(piece.y / Board_Manager.tile_size) * Board_Manager.tile_size;
    var grid_to_x = round(move.to_x / Board_Manager.tile_size) * Board_Manager.tile_size;
    var grid_to_y = round(move.to_y / Board_Manager.tile_size) * Board_Manager.tile_size;
    
    piece.x = grid_from_x;
    piece.y = grid_from_y;
    
    // Validate move distance for knight
    if (piece.piece_id == "knight") {
        var dx = abs((grid_to_x - grid_from_x) / Board_Manager.tile_size);
        var dy = abs((grid_to_y - grid_from_y) / Board_Manager.tile_size);
        
        if (!((dx == 2 && dy == 1) || (dx == 1 && dy == 2))) {
            show_debug_message("AI Error: Invalid knight move distance");
            Game_Manager.turn = 0;
            return false;
        }
    }
    
    // Check if target square is actually different
    if (point_distance(grid_from_x, grid_from_y, grid_to_x, grid_to_y) < 1) {
        show_debug_message("AI Error: Move to same square");
        Game_Manager.turn = 0;
        return false;
    }
    
    // Handle capture BEFORE moving
    if (move.is_capture && move.captured_piece != noone && instance_exists(move.captured_piece)) {
        var captured_piece_id = move.captured_piece.piece_id;
        instance_destroy(move.captured_piece);
        show_debug_message("AI: Captured " + captured_piece_id);
    }
    
    // IMMEDIATE POSITION CHANGE (no animation for now to prevent loops)
    piece.x = grid_to_x;
    piece.y = grid_to_y;
    piece.has_moved = true;
    
    // CRITICAL: Force immediate turn switch
    Game_Manager.turn = 0;
    Game_Manager.selected_piece = noone;
    
    // Record move for loop prevention
    if (!variable_global_exists("ai_last_moves")) {
        global.ai_last_moves = [];
    }
    
    var move_string = piece.piece_id + ":" + string(grid_from_x) + "," + string(grid_from_y) + "->" + string(grid_to_x) + "," + string(grid_to_y);
    array_push(global.ai_last_moves, move_string);
    
    // Keep only last 10 moves
    if (array_length(global.ai_last_moves) > 10) {
        array_delete(global.ai_last_moves, 0, 1);
    }
    
    show_debug_message("AI: " + move_string);
    show_debug_message("AI: Turn switched to WHITE");
    
    return true;
}