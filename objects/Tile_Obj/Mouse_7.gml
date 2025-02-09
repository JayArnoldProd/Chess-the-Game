// -----------------------------
// Tile_Obj Left Released Event
// -----------------------------

if (Game_Manager.moveCancelled) {
    Game_Manager.moveCancelled = false; // reset the flag
    valid_move = false;
    exit;
}

selected_piece = Game_Manager.selected_piece;

if (valid_move and (Game_Manager.selected_piece != noone)) {
    var piece = Game_Manager.selected_piece;
    
    if (piece.stepping_chain > 0) {
        if (piece.stepping_chain == 2) {
            // --- EXTRA MOVE PHASE 1 ---
            piece.x = x;
            piece.y = y;
            audio_play_sound_on(audio_emitter, Stone_Slide1_SFX, 0, false);
            piece.stepping_stone_instance.x = x;
            piece.stepping_stone_instance.y = y;
            piece.stepping_chain = 1;  // Advance to Phase 2
            show_debug_message("Stepping stone extra move phase 1 completed. Now choose your next move.");
            // Do not deselect the piece here.
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
            show_debug_message("Stepping stone chain complete; turn ends.");
    
            // --- CAPTURE CHECK FOR EXTRA MOVE PHASE 2 ---
            // Loop over all Chess_Piece_Obj to find an enemy overlapping the destination.
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
    
            // Switch turns after a completed extra move.
            if (piece.piece_type == 0) {
                Game_Manager.turn = 1;
            } else if (piece.piece_type == 1) {
                Game_Manager.turn = 0;
            }
            Game_Manager.selected_piece = noone;
        }
        valid_move = false;
    }
    else {
        // --- NORMAL MOVE PROCESSING ---
    
        // Play landing sounds.
        if (!instance_position(x + tile_size/4, y + tile_size/4, Stepping_Stone_Obj)) {
            audio_play_sound_on(audio_emitter, Piece_Landing_SFX, 0, false);
            // Switch turn: white moves -> turn becomes 1 (black), black moves -> turn becomes 0 (white)
            if (piece.piece_type == 0) {
                Game_Manager.turn = 1;
            } else if (piece.piece_type == 1) {
                Game_Manager.turn = 0;
            }
        } else {
            audio_play_sound_on(audio_emitter, Piece_StoneLanding_SFX, 0, false);
        }
    
        // --- CAPTURE CHECK (NORMAL MOVE) ---
        // Do this *before* moving the piece so the enemy is still there.
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
    
        // --- WATER / VOID CHECK ---
        // First, check for void: if the tile is void (tile_type == -1), destroy the piece.
        if (tile_type = -1) { // void tile
            instance_destroy(piece);
            //audio_play_sound_on(audio_emitter, Water_Splash_SFX, 0, false);
            Game_Manager.selected_piece = noone;
            valid_move = false;
            exit;
        }
    
        // Then check for water: if the tile is water (tile_type == 1)...
        if (tile_type = 1) { // water tile
            // Use the tile's center (x,y) to check for a Bridge_Obj.
            if (!instance_position(x+tile_size/4, y+tile_size/4, Bridge_Obj)) { 
                // No bridge is present, so destroy the piece.
                instance_destroy(piece);
                audio_play_sound_on(audio_emitter, Piece_Drowning_SFX, 0, false);
                Game_Manager.selected_piece = noone;
                valid_move = false;
                exit;
            }
        }
    
        Game_Manager.selected_piece = noone;
        valid_move = false;
    }
}