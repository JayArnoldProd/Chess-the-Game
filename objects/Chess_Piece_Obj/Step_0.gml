// -----------------------------
// Chess_Piece_Obj Step Event
// -----------------------------

// 1. Update audio emitter and record last position.
audio_emitter_position(audio_emitter, x, y, 0);
last_x = x;
last_y = y;

// Set depth based on movement: while moving, set to -2; otherwise, normal depth (-1).
if (is_moving) {
    depth = -2;
}

// 2. Movement Interpolation (Animation)
if (is_moving) {
    move_progress += 1 / move_duration;
    if (move_progress >= 1) {
        move_progress = 1;
        is_moving = false;
        // Snap exactly to the target grid.
        x = move_target_x;
        y = move_target_y;
    } else {
        var t = easeInOutQuad(move_progress);
        if (move_animation_type == "linear") {
            x = lerp(move_start_x, move_target_x, t);
            y = lerp(move_start_y, move_target_y, t);
        } else if (move_animation_type == "knight") {
            // Two-phase interpolation for knight's L-shaped move.
            if (move_progress < 0.5) {
                var t_phase = easeInOutQuad(move_progress * 2);
                y = lerp(move_start_y, move_target_y, t_phase);
                x = move_start_x;
            } else {
                var t_phase = easeInOutQuad((move_progress - 0.5) * 2);
                y = move_target_y;
                x = lerp(move_start_x, move_target_x, t_phase);
            }
        }
    }
}

if (!is_moving) {
    // If marked for destruction, check if the piece has reached the target tile.
    if (destroy_pending) {
        if (abs(x - destroy_target_x) < 1 && abs(y - destroy_target_y) < 1) {
            x = destroy_target_x;
            y = destroy_target_y;
            if (destroy_tile_type == 1) {
                audio_play_sound_on(audio_emitter, Piece_Drowning_SFX, 0, false);
            } else {
                audio_play_sound_on(audio_emitter, Piece_Landing_SFX, 0, false);
            }
            instance_destroy();
        }
    }
    
    // Otherwise, if landing_sound_pending is still true (for a normal move), play landing sound.
    if (landing_sound_pending) {
        audio_play_sound_on(audio_emitter, landing_sound, 0, false);
        landing_sound_pending = false;
    }
}

// 3. Stepping Stone Activation & Extra-Move Valid Moves
// ONLY process stepping stone logic if this is NOT an AI piece during AI turn
// AI pieces handle stepping stones explicitly via AI_Manager, not this auto-detection
if (!(piece_type == 1 && Game_Manager.turn == 1)) {
    if (!is_moving) {
        // Only PLAYER pieces (piece_type == 0) should auto-detect stepping stones
        // AI pieces use ai_execute_move_animated which sets up stepping stone state explicitly
        if (stepping_chain == 0 && piece_type == 0) {
            var stone = instance_position(x, y, Stepping_Stone_Obj);
            if (stone != noone) {
                // Use previous frame's position as reference.
                pre_stepping_x = last_x;
                pre_stepping_y = last_y;
                
                extra_move_pending = true;
                stepping_chain = 2;  // Phase 1 extra move pending.
                stepping_stone_instance = stone;
                stone_original_x = stone.x;
                stone_original_y = stone.y;
                show_debug_message("Stepping stone activated! Extra move phase 1 available.");
            }
        }
    }

    // While in extra–move Phase 1, override valid moves to the 8 adjacent directions.
    // Only applies to player pieces - AI calculates its own valid moves
    if (!is_moving && stepping_chain == 2 && piece_type == 0) {
        valid_moves = [];
        for (var dx = -1; dx <= 1; dx++) {
            for (var dy = -1; dy <= 1; dy++) {
                if (dx != 0 || dy != 0) {
                    array_push(valid_moves, [dx, dy]);
                }
            }
        }
    }

    // Force the piece to remain selected if in any extra–move chain.
    // Only player pieces should auto-select - AI pieces are controlled by AI_Manager
    if (stepping_chain > 0 && piece_type == 0) {
        Game_Manager.selected_piece = self;
    }
}

// 4. Deferred Move Finalization (Post-Animation)
// Once not moving, process any pending flags.
if (!is_moving) {
    // If this was a normal move (not extra–move or castling), process en passant and capture.
    if (pending_normal_move) {
        pending_normal_move = false;
        // Process en passant capture if flagged.
        if (piece_id == "pawn" && pending_en_passant) {
            pending_en_passant = false;
            if (instance_exists(Game_Manager.en_passant_pawn)) {
                instance_destroy(Game_Manager.en_passant_pawn);
                audio_play_sound_on(audio_emitter, Piece_Capture_SFX, 0, false);
            }
            pending_turn_switch = (piece_type == 0) ? 1 : 0;
        }
        // Mark pawn as en passant vulnerable if it moved two squares.
        if (piece_id == "pawn" && abs(original_turn_y - y) == Board_Manager.tile_size * 2) {
            Game_Manager.en_passant_target_x = x;
            Game_Manager.en_passant_target_y = (original_turn_y + y) / 2;
            en_passant_vulnerable = true;
            Game_Manager.en_passant_pawn = self;
        } else {
            en_passant_vulnerable = false;
            Game_Manager.en_passant_target_x = -1;
            Game_Manager.en_passant_target_y = -1;
            Game_Manager.en_passant_pawn = noone;
        }
    }
    
    // Process any pending capture (for normal or extra moves).
    if (pending_capture != noone) {
        pending_capture.health_ -= 1;
        if (pending_capture.health_ <= 0) {
            instance_destroy(pending_capture);
            audio_play_sound_on(audio_emitter, Piece_Capture_SFX, 0, false);
        }
        pending_capture = noone;
    }
    
    // Process deferred turn switch.
    if (pending_turn_switch != undefined) {
        // Don't switch turns if this is an AI piece in a stepping stone sequence
        var skip_turn_switch = false;
        
        if (piece_type == 1 && stepping_chain > 0) {
            // This is an AI piece in stepping stone sequence - check if AI is handling it
            if (instance_exists(AI_Manager) && 
                variable_instance_exists(AI_Manager, "ai_stepping_phase") && 
                AI_Manager.ai_stepping_phase > 0) {
                skip_turn_switch = true;
                show_debug_message("Prevented turn switch during AI stepping stone sequence");
            }
        }
        
        if (!skip_turn_switch) {
            Game_Manager.turn = pending_turn_switch;
            pending_turn_switch = undefined;
        }
    }
}