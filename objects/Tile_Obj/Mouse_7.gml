// -----------------------------
// Tile_Obj Left Released Event
// -----------------------------
if (Game_Manager.moveCancelled) {
    Game_Manager.moveCancelled = false; // reset flag
    valid_move = false;
    exit;
}

selected_piece = Game_Manager.selected_piece;
if (valid_move and (selected_piece != noone)) {
    var piece = selected_piece;
    
    // ==============================
    // STEPPING STONE MOVE PROCESSING
    // ==============================
    if (piece.stepping_chain > 0) {
        if (piece.stepping_chain == 2) {
            // --- EXTRA MOVE PHASE 1 ---
            piece.move_start_x = piece.x;
            piece.move_start_y = piece.y;
            piece.move_target_x = x;
            piece.move_target_y = y;
            piece.move_progress = 0;
            piece.move_duration = 30;
            piece.is_moving = true;
            // Force linear movement when riding the stone.
            piece.move_animation_type = "linear";
            if (piece.stepping_stone_instance != noone) {
                piece.stepping_stone_instance.move_start_x = piece.stepping_stone_instance.x;
                piece.stepping_stone_instance.move_start_y = piece.stepping_stone_instance.y;
                piece.stepping_stone_instance.move_target_x = x;
                piece.stepping_stone_instance.move_target_y = y;
                piece.stepping_stone_instance.move_progress = 0;
                piece.stepping_stone_instance.move_duration = 30;
                piece.stepping_stone_instance.is_moving = true;
            }
            audio_play_sound_on(audio_emitter, Stone_Slide1_SFX, 0, false);
            piece.stepping_chain = 1;  // Advance to Phase 2
            show_debug_message("Stepping stone phase 1 complete. Choose your next move.");
        }
        else if (piece.stepping_chain == 1) {
            // --- EXTRA MOVE PHASE 2 ---
            piece.move_start_x = piece.x;
            piece.move_start_y = piece.y;
            piece.move_target_x = x;
            piece.move_target_y = y;
            piece.move_progress = 0;
            piece.move_duration = 30;
            piece.is_moving = true;
            // Use knight animation if applicable.
            piece.move_animation_type = (piece.piece_id == "knight") ? "knight" : "linear";
            audio_play_sound_on(audio_emitter, Stone_Slide2_SFX, 0, false);
            piece.landing_sound= Piece_Landing_SFX;
			piece.landing_sound_pending = true;
            if (piece.stepping_stone_instance != noone) {
                piece.stepping_stone_instance.move_start_x = piece.stepping_stone_instance.x;
                piece.stepping_stone_instance.move_start_y = piece.stepping_stone_instance.y;
                piece.stepping_stone_instance.move_target_x = piece.stone_original_x;
                piece.stepping_stone_instance.move_target_y = piece.stone_original_y;
                piece.stepping_stone_instance.move_progress = 0;
                piece.stepping_stone_instance.move_duration = 30;
                piece.stepping_stone_instance.is_moving = true;
            }
            // End extra–move immediately.
            piece.stepping_chain = 0;
            piece.extra_move_pending = false;
            piece.stepping_stone_instance = noone;
            show_debug_message("Stepping stone phase 2 complete; turn ends.");
            
            // Capture check for extra move (using your original loop):
            var enemyFound = noone;
            var cnt = instance_number(Chess_Piece_Obj);
            for (var i = 0; i < cnt; i++) {
                var inst = instance_find(Chess_Piece_Obj, i);
                if (inst != piece && inst.piece_type != piece.piece_type) {
                    if (point_distance(x, y, inst.x, inst.y) < Board_Manager.tile_size * 0.5) {
                        enemyFound = inst;
                        break;
                    }
                }
            }
            if (enemyFound != noone) {
                piece.pending_capture = enemyFound; // Defer capture until animation completes.
            }
            
            // Mark turn switch (to occur after animation completes).
            piece.pending_turn_switch = (piece.piece_type == 0) ? 1 : 0;
            // Clear any en passant pending flag from an extra move.
            piece.pending_en_passant = false;
            Game_Manager.selected_piece = noone;
        }
        valid_move = false;
    }
    // ==============================
    // CASTLING CHECK (for kings)
    // ==============================
    else if (piece.object_index == King_Obj && array_length(piece.castle_moves) > 0) {
        var executedCastle = false;
        for (var i = 0; i < array_length(piece.castle_moves); i++) {
            var move = piece.castle_moves[i]; // Format: [castle_dx, 0, "castle", rook_id]
            var castle_target_x = piece.x + move[0] * Board_Manager.tile_size;
            var castle_target_y = piece.y;
            if (point_distance(x, y, castle_target_x, castle_target_y) < Board_Manager.tile_size/2) {
                piece.move_start_x = piece.x;
                piece.move_start_y = piece.y;
                piece.move_target_x = castle_target_x;
                piece.move_target_y = castle_target_y;
                piece.move_progress = 0;
                piece.move_duration = 30;
                piece.is_moving = true;
                // For castling we always use linear animation.
                piece.move_animation_type = "linear";
                piece.has_moved = true;
                
                var rookFound = noone;
                var cnt2 = instance_number(Rook_Obj);
                for (var j = 0; j < cnt2; j++) {
                    var r = instance_find(Rook_Obj, j);
                    if (r.id == move[3]) {
                        rookFound = r;
                        break;
                    }
                }
                if (rookFound != noone) {
                    rookFound.move_start_x = rookFound.x;
                    rookFound.move_start_y = rookFound.y;
                    if (move[0] > 0) {
                        rookFound.move_target_x = castle_target_x - Board_Manager.tile_size;
                    } else {
                        rookFound.move_target_x = castle_target_x + Board_Manager.tile_size;
                    }
                    rookFound.move_target_y = castle_target_y;
                    rookFound.move_progress = 0;
                    rookFound.move_duration = 30;
                    rookFound.is_moving = true;
                    rookFound.has_moved = true;
                }
                piece.castle_moves = [];
                piece.pending_turn_switch = (piece.piece_type == 0) ? 1 : 0;
                Game_Manager.selected_piece = noone;
                valid_move = false;
                executedCastle = true;
				piece.landing_sound= Piece_Landing_SFX;
				piece.landing_sound_pending = true;
                exit;
            }
        }
        if (executedCastle) exit;
    }
    // ==============================
    // NORMAL MOVE PROCESSING
    // ==============================
    else {
        // Determine landing sound.
        if (!instance_position(x + Board_Manager.tile_size/4, y + Board_Manager.tile_size/4, Stepping_Stone_Obj)) {
            piece.landing_sound= Piece_Landing_SFX;
			piece.landing_sound_pending = true;
            piece.pending_turn_switch = (piece.piece_type == 0) ? 1 : 0;
        } else {
			piece.landing_sound= Piece_StoneLanding_SFX;
			piece.landing_sound_pending = true;
        }
    
        // Normal capture check.
        var enemy = instance_position(x, y, Chess_Piece_Obj);
        if (enemy != noone && enemy != piece && enemy.piece_type != piece.piece_type) {
            piece.pending_capture = enemy;
        }
    
        // Set up animated move.
        piece.move_start_x = piece.x;
        piece.move_start_y = piece.y;
        piece.move_target_x = x;
        piece.move_target_y = y;
        piece.move_progress = 0;
        piece.move_duration = 30;
        piece.is_moving = true;
        // For normal moves, knights use their L-shaped animation.
        piece.move_animation_type = (piece.piece_id == "knight") ? "knight" : "linear";
        piece.has_moved = true;
    
        // En passant capture check:
        if (piece.piece_id == "pawn") {
            if (x == Game_Manager.en_passant_target_x && y == Game_Manager.en_passant_target_y) {
                piece.pending_en_passant = true;
            } else {
                piece.pending_en_passant = false;
            }
        }
        piece.pending_normal_move = true;
    
        // WATER / VOID CHECKS:
        // Save the tile's coordinates in local variables.
        var tile_dest_x = x;
        var tile_dest_y = y;
    
        if (tile_type == -1) { // void tile
            // Mark the piece to be destroyed once it reaches the target tile.
            piece.destroy_pending = true;
            piece.destroy_target_x = tile_dest_x;
            piece.destroy_target_y = tile_dest_y;
        }
        if (tile_type == 1) { // water tile
            if (!instance_position(tile_dest_x + Board_Manager.tile_size/4, tile_dest_y + Board_Manager.tile_size/4, Bridge_Obj)) {
                piece.destroy_pending = true;
                piece.destroy_target_x = tile_dest_x;
                piece.destroy_target_y = tile_dest_y;
                piece.destroy_tile_type = 1;
            }
        }
    
        Game_Manager.selected_piece = noone;
        valid_move = false;
    }
}