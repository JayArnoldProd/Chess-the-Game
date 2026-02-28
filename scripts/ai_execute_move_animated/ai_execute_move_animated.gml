/// @function ai_execute_move_animated(move)
/// @param {struct} move The move to execute
/// @description Executes AI move with proper stepping stone, castling, and turn handling
function ai_execute_move_animated(move) {
    if (!instance_exists(move.piece)) return false;
    
    var piece = move.piece;
    
    // Snap positions to grid
    var to_x = round(move.to_x / Board_Manager.tile_size) * Board_Manager.tile_size;
    var to_y = round(move.to_y / Board_Manager.tile_size) * Board_Manager.tile_size;
    
    // Check for castling move
    var special = variable_struct_exists(move, "special") ? move.special : "";
    
    if (special == "castle_k" || special == "castle_q") {
        // CASTLING MOVE
        show_debug_message("AI: Executing castling move (" + special + ")");
        
        // Move the king
        piece.move_start_x = piece.x;
        piece.move_start_y = piece.y;
        piece.move_target_x = to_x;
        piece.move_target_y = to_y;
        piece.move_progress = 0;
        piece.move_duration = 30;
        piece.is_moving = true;
        piece.has_moved = true;
        piece.move_animation_type = "linear";
        
        // Find and move the rook
        var rook_from_x, rook_to_x;
        if (special == "castle_k") {
            // Kingside: rook goes from col 7 to col 5
            rook_from_x = Object_Manager.topleft_x + 7 * Board_Manager.tile_size;
            rook_to_x = to_x - Board_Manager.tile_size; // One square left of king's destination
        } else {
            // Queenside: rook goes from col 0 to col 3
            rook_from_x = Object_Manager.topleft_x + 0 * Board_Manager.tile_size;
            rook_to_x = to_x + Board_Manager.tile_size; // One square right of king's destination
        }
        
        // Find the rook
        with (Rook_Obj) {
            if (piece_type == 1 && point_distance(x, y, rook_from_x, to_y) < Board_Manager.tile_size / 2) {
                move_start_x = x;
                move_start_y = y;
                move_target_x = rook_to_x;
                move_target_y = y;
                move_progress = 0;
                move_duration = 30;
                is_moving = true;
                has_moved = true;
                move_animation_type = "linear";
                show_debug_message("AI: Moving rook from " + string(x) + " to " + string(rook_to_x));
                break;
            }
        }
        
        piece.landing_sound = Piece_Landing_SFX;
        piece.landing_sound_pending = true;
        piece.pending_turn_switch = 0;
        piece.pending_normal_move = false;
        
        Game_Manager.selected_piece = noone;
        return true;
    }
    
    // Defer capture until animation completes (prevents piece disappearing at start of animation)
    if (move.is_capture && move.captured_piece != noone && instance_exists(move.captured_piece)) {
        piece.pending_capture = move.captured_piece;
    }
    
    // Set up animated move
    piece.move_start_x = piece.x;
    piece.move_start_y = piece.y;
    piece.move_target_x = to_x;
    piece.move_target_y = to_y;
    piece.move_progress = 0;
    piece.move_duration = 30;
    piece.is_moving = true;
    piece.has_moved = true;
    
    // Set animation type
    piece.move_animation_type = (piece.piece_id == "knight") ? "knight" : "linear";
    
    // Check if moving to a stepping stone
    var target_tile = instance_place(to_x, to_y, Tile_Obj);
    var on_stepping_stone = instance_position(to_x + Board_Manager.tile_size/4, to_y + Board_Manager.tile_size/4, Stepping_Stone_Obj);
    
    // Also check exact position and small radius (stepping stones can be slightly offset)
    if (!on_stepping_stone) {
        on_stepping_stone = instance_position(to_x, to_y, Stepping_Stone_Obj);
    }
    if (!on_stepping_stone) {
        with (Stepping_Stone_Obj) {
            if (point_distance(x, y, to_x, to_y) < Board_Manager.tile_size * 0.75) {
                on_stepping_stone = id;
                break;
            }
        }
    }
    
    show_debug_message("AI: Moving " + piece.piece_id + " to (" + string(to_x) + "," + string(to_y) + ")");
    show_debug_message("AI: Stepping stone check: " + (on_stepping_stone ? "FOUND at (" + string(on_stepping_stone.x) + "," + string(on_stepping_stone.y) + ")" : "none"));
    
    if (on_stepping_stone && instance_exists(on_stepping_stone)) {
        // Landing on stepping stone - AI handles it directly (existing system skips AI pieces)
        piece.landing_sound = Piece_StoneLanding_SFX;
        piece.landing_sound_pending = true;
        
        // DO NOT set pending_turn_switch - stepping stone sequence will manage turns
        piece.pending_turn_switch = undefined;
        piece.pending_normal_move = false;
        
        // Set up stepping stone state on the piece (since existing system won't)
        piece.stepping_chain = 2;  // Phase 1: 8-directional move pending
        piece.extra_move_pending = true;
        piece.stepping_stone_instance = on_stepping_stone;
        piece.stone_original_x = on_stepping_stone.x;
        piece.stone_original_y = on_stepping_stone.y;
        piece.pre_stepping_x = piece.x;
        piece.pre_stepping_y = piece.y;
        
        // Tell AI Manager to handle stepping stone sequence
        AI_Manager.ai_stepping_phase = 1; // Phase 1: ready to make 8-directional move
        AI_Manager.ai_stepping_piece = piece;
        
        show_debug_message("AI: Landing on stepping stone - AI will handle phases directly");
        show_debug_message("AI: Stone at (" + string(on_stepping_stone.x) + "," + string(on_stepping_stone.y) + ")");
        
    } else {
        // Normal move - switch turns after animation
        piece.landing_sound = Piece_Landing_SFX;
        piece.landing_sound_pending = true;
        piece.pending_turn_switch = 0; // Switch to player turn
        piece.pending_normal_move = true;
        
        // --- WATER / VOID HAZARD CHECKS FOR AI ---
        // Check the destination tile for hazards (same as Tile_Obj/Mouse_7.gml does for player)
        if (instance_exists(target_tile) && variable_instance_exists(target_tile, "tile_type")) {
            var tile_type = target_tile.tile_type;
            
            if (tile_type == -1) {
                // VOID TILE - AI piece will be destroyed
                piece.destroy_pending = true;
                piece.destroy_target_x = to_x;
                piece.destroy_target_y = to_y;
                piece.destroy_tile_type = -1;
                show_debug_message("AI: Moving to VOID tile - piece will be destroyed!");
            } else if (tile_type == 1) {
                // WATER TILE - check for bridge
                var has_bridge = instance_position(to_x + Board_Manager.tile_size/4, to_y + Board_Manager.tile_size/4, Bridge_Obj);
                if (!has_bridge) {
                    has_bridge = instance_position(to_x, to_y, Bridge_Obj);
                }
                if (!has_bridge) {
                    // Check by proximity (bridges can be slightly offset)
                    with (Bridge_Obj) {
                        if (point_distance(x, y, to_x, to_y) < Board_Manager.tile_size * 0.75) {
                            has_bridge = id;
                            break;
                        }
                    }
                }
                
                if (!has_bridge) {
                    // No bridge - AI piece will drown
                    piece.destroy_pending = true;
                    piece.destroy_target_x = to_x;
                    piece.destroy_target_y = to_y;
                    piece.destroy_tile_type = 1;
                    show_debug_message("AI: Moving to WATER tile without bridge - piece will drown!");
                }
            }
        }
        
        show_debug_message("AI: Normal move, will switch to player turn");
    }
    
    Game_Manager.selected_piece = noone;
    return true;
}