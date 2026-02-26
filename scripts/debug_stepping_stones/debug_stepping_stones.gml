/// @function debug_stepping_stones()
/// @description Debug function to check stepping stone locations
function debug_stepping_stones() {
    show_debug_message("=== STEPPING STONE DEBUG ===");
    
    var stone_count = 0;
    with (Stepping_Stone_Obj) {
        if (instance_exists(id)) {
            stone_count++;
            show_debug_message("Stepping Stone " + string(stone_count) + " at (" + string(x) + "," + string(y) + ")");
            
            // Check what pieces are around this stone
            for (var dx = -1; dx <= 1; dx++) {
                for (var dy = -1; dy <= 1; dy++) {
                    if (dx == 0 && dy == 0) continue;
                    
                    var check_x = x + dx * Board_Manager.tile_size;
                    var check_y = y + dy * Board_Manager.tile_size;
                    var piece_here = instance_position(check_x, check_y, Chess_Piece_Obj);
                    
                    if (piece_here) {
                        show_debug_message("  " + string(dx) + "," + string(dy) + ": " + piece_here.piece_id + " (" + (piece_here.piece_type == 0 ? "white" : "black") + ")");
                    } else {
                        var tile_here = instance_place(check_x, check_y, Tile_Obj);
                        if (tile_here) {
                            show_debug_message("  " + string(dx) + "," + string(dy) + ": EMPTY");
                        } else {
                            show_debug_message("  " + string(dx) + "," + string(dy) + ": OFF BOARD");
                        }
                    }
                }
            }
        }
    }
    
    if (stone_count == 0) {
        show_debug_message("No stepping stones found on board!");
    } else {
        show_debug_message("Total stepping stones: " + string(stone_count));
    }
    
    // Check AI piece positions and stepping states
    var ai_pieces = 0;
    with (Chess_Piece_Obj) {
        if (piece_type == 1) { // Black AI pieces
            ai_pieces++;
            var near_stone = instance_position(x + Board_Manager.tile_size/4, y + Board_Manager.tile_size/4, Stepping_Stone_Obj);
            if (near_stone) {
                show_debug_message("AI " + piece_id + " at (" + string(x) + "," + string(y) + ") is ON a stepping stone!");
                show_debug_message("  stepping_chain: " + string(stepping_chain));
                show_debug_message("  extra_move_pending: " + string(extra_move_pending));
                
                // If this piece is on a stone, show what moves it has available
                if (stepping_chain == 2) {
                    show_debug_message("  Should have 8-directional moves:");
                    for (var dx = -1; dx <= 1; dx++) {
                        for (var dy = -1; dy <= 1; dy++) {
                            if (dx == 0 && dy == 0) continue;
                            
                            var target_x = x + dx * Board_Manager.tile_size;
                            var target_y = y + dy * Board_Manager.tile_size;
                            var tile = instance_place(target_x, target_y, Tile_Obj);
                            var blocking = instance_position(target_x, target_y, Chess_Piece_Obj);
                            
                            if (!tile) {
                                show_debug_message("    " + string(dx) + "," + string(dy) + ": OFF BOARD");
                            } else if (blocking) {
                                show_debug_message("    " + string(dx) + "," + string(dy) + ": BLOCKED by " + blocking.piece_id);
                            } else {
                                show_debug_message("    " + string(dx) + "," + string(dy) + ": AVAILABLE");
                            }
                        }
                    }
                }
            }
        }
    }
    
    show_debug_message("Total AI pieces: " + string(ai_pieces));
    show_debug_message("=== END DEBUG ===");
}