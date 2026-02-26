/// @function ai_force_stepping_stone_move()
/// @description Forces AI to make a stepping stone move if possible
function ai_force_stepping_stone_move() {
    show_debug_message("=== FORCING AI STEPPING STONE MOVE ===");
    
    // Stop any current animations first
    with (Chess_Piece_Obj) {
        if (is_moving) {
            is_moving = false;
            x = round(x / Board_Manager.tile_size) * Board_Manager.tile_size;
            y = round(y / Board_Manager.tile_size) * Board_Manager.tile_size;
        }
    }
    with (Stepping_Stone_Obj) {
        if (is_moving) {
            is_moving = false;
            x = round(x / Board_Manager.tile_size) * Board_Manager.tile_size;
            y = round(y / Board_Manager.tile_size) * Board_Manager.tile_size;
        }
    }
    
    // Reset AI state
    AI_Manager.ai_stepping_phase = 0;
    AI_Manager.ai_stepping_piece = noone;
    
    if (Game_Manager.turn != 1) {
        Game_Manager.turn = 1;
        show_debug_message("Switched to AI turn");
    }
    
    var moves = ai_get_legal_moves_safe(1);
    var stone_moves = [];
    
    for (var i = 0; i < array_length(moves); i++) {
        var move = moves[i];
        var on_stone = instance_position(move.to_x + Board_Manager.tile_size/4, move.to_y + Board_Manager.tile_size/4, Stepping_Stone_Obj);
        if (on_stone) {
            array_push(stone_moves, move);
            show_debug_message("Found stepping stone move: " + move.piece_id + " to (" + string(move.to_x) + "," + string(move.to_y) + ")");
        }
    }
    
    if (array_length(stone_moves) > 0) {
        var chosen_move = stone_moves[0];
        show_debug_message("FORCING stepping stone move with " + chosen_move.piece_id);
        
        // Force the move to execute
        var success = ai_execute_move_animated(chosen_move);
        if (success) {
            show_debug_message("✓ Stepping stone move executed successfully");
        } else {
            show_debug_message("✗ Failed to execute stepping stone move");
        }
    } else {
        show_debug_message("No stepping stone moves available");
        
        // Show what moves ARE available
        show_debug_message("Available moves:");
        for (var i = 0; i < min(5, array_length(moves)); i++) {
            var move = moves[i];
            show_debug_message("  " + move.piece_id + " to (" + string(move.to_x) + "," + string(move.to_y) + ")");
        }
    }
}