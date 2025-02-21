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
            piece.x = x;
            piece.y = y;
            audio_play_sound_on(audio_emitter, Stone_Slide1_SFX, 0, false);
            piece.stepping_stone_instance.x = x;
            piece.stepping_stone_instance.y = y;
            piece.stepping_chain = 1;  // Advance to Phase 2
            show_debug_message("Stepping stone phase 1 complete. Choose your next move.");
        }
        else if (piece.stepping_chain == 1) {
            // --- EXTRA MOVE PHASE 2 ---
            piece.x = x;
            piece.y = y;
            audio_play_sound_on(audio_emitter, Stone_Slide2_SFX, 0, false);
            audio_play_sound_on(audio_emitter, Piece_Landing_SFX, 0, false);
            piece.stepping_stone_instance.x = piece.stone_original_x;
            piece.stepping_stone_instance.y = piece.stone_original_y;
            piece.stepping_chain = 0;
            piece.extra_move_pending = false;
            piece.stepping_stone_instance = noone;
            show_debug_message("Stepping stone phase 2 complete; turn ends.");
            
            // Capture check for extra move:
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
                enemyFound.health_ -= 1;
                if (enemyFound.health_ <= 0) {
                    instance_destroy(enemyFound);
                }
            }
            
            // Switch turn.
            if (piece.piece_type == 0) {
                Game_Manager.turn = 1;
            } else {
                Game_Manager.turn = 0;
            }
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
                // Execute castle move.
                piece.x = castle_target_x;
                piece.y = castle_target_y;
                piece.has_moved = true;
                // Find corresponding rook.
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
                    if (move[0] > 0) {
                        rookFound.x = piece.x - Board_Manager.tile_size;
                        rookFound.y = piece.y;
                    } else {
                        rookFound.x = piece.x + Board_Manager.tile_size;
                        rookFound.y = piece.y;
                    }
                    rookFound.has_moved = true;
                }
                piece.castle_moves = [];
                if (piece.piece_type == 0) {
                    Game_Manager.turn = 1;
                } else {
                    Game_Manager.turn = 0;
                }
                Game_Manager.selected_piece = noone;
                valid_move = false;
                executedCastle = true;
                exit;
            }
        }
        if (executedCastle) exit;
    }
    // ==============================
    // NORMAL MOVE PROCESSING
    // ==============================
    else {
        // Play landing sounds.
        if (!instance_position(x + Board_Manager.tile_size/4, y + Board_Manager.tile_size/4, Stepping_Stone_Obj)) {
            audio_play_sound_on(audio_emitter, Piece_Landing_SFX, 0, false);
            if (piece.piece_type == 0) {
                Game_Manager.turn = 1;
            } else {
                Game_Manager.turn = 0;
            }
        } else {
            audio_play_sound_on(audio_emitter, Piece_StoneLanding_SFX, 0, false);
        }
    
        // --- CAPTURE CHECK (NORMAL MOVE) ---
        var enemy = instance_position(x, y, Chess_Piece_Obj);
        if (enemy != noone && enemy != piece && enemy.piece_type != piece.piece_type) {
            if (variable_instance_exists(enemy, "health_")) {
                enemy.health_ -= 1;
                if (enemy.health_ <= 0) {
                    instance_destroy(enemy);
                    audio_play_sound_on(audio_emitter, Piece_Capture_SFX, 0, false);
                }
            } else {
                show_debug_message("Error: captured object does not have a health_ variable!");
            }
        }
    
        // --- MOVE THE PIECE ---
        piece.x = x;
        piece.y = y;
        piece.has_moved = true;
        
        // --- EN PASSANT CAPTURE CHECK ---
        if (piece.piece_id == "pawn") {
            // If the clicked tile is the en passant target square…
            if (x == Game_Manager.en_passant_target_x && y == Game_Manager.en_passant_target_y) {
                if (instance_exists(Game_Manager.en_passant_pawn)) {
                    instance_destroy(Game_Manager.en_passant_pawn);
                    audio_play_sound_on(audio_emitter, Piece_Capture_SFX, 0, false);
                }
            }
        }
        
        // --- MARK PAWN AS EN PASSANT VULNERABLE IF MOVED TWO SQUARES ---
        if (piece.piece_id == "pawn" && abs(piece.original_turn_y - piece.y) == Board_Manager.tile_size * 2) {
            // Set the target square to the midpoint between starting and ending y positions.
            Game_Manager.en_passant_target_x = piece.x;
            Game_Manager.en_passant_target_y = (piece.original_turn_y + piece.y) / 2;
            piece.en_passant_vulnerable = true;
            Game_Manager.en_passant_pawn = piece;
        } else {
            piece.en_passant_vulnerable = false;
            Game_Manager.en_passant_target_x = -1;
            Game_Manager.en_passant_target_y = -1;
            Game_Manager.en_passant_pawn = noone;
        }
        
        // --- WATER / VOID CHECK ---
        if (tile_type == -1) { // void tile
            instance_destroy(piece);
            Game_Manager.selected_piece = noone;
            valid_move = false;
            exit;
        }
    
        if (tile_type == 1) { // water tile
            with (piece) {
                if (!instance_position(x + Board_Manager.tile_size/4, y + Board_Manager.tile_size/4, Bridge_Obj)) { 
                    instance_destroy();
                    audio_play_sound_on(audio_emitter, Piece_Drowning_SFX, 0, false);
                    Game_Manager.selected_piece = noone;
                    valid_move = false;
                    exit;
                }
            }
        }
    
        Game_Manager.selected_piece = noone;
        valid_move = false;
    }
}