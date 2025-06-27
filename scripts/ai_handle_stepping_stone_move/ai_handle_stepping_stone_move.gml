function ai_handle_stepping_stone_move() {
    var piece = AI_Manager.ai_stepping_piece;
    
    if (!instance_exists(piece) || piece.is_moving) {
        return; // Wait for current animation to finish
    }
    
    // Check if piece is actually on a stepping stone
    var on_stone = instance_position(piece.x + Board_Manager.tile_size/4, piece.y + Board_Manager.tile_size/4, Stepping_Stone_Obj);
    if (!on_stone && AI_Manager.ai_stepping_phase == 1) {
        // Not on stone, end stepping sequence
        AI_Manager.ai_stepping_phase = 0;
        AI_Manager.ai_stepping_piece = noone;
        Game_Manager.turn = 0; // End AI turn
        return;
    }
    
    if (AI_Manager.ai_stepping_phase == 1) {
        // Phase 1: 8-directional move
        show_debug_message("AI: Stepping stone phase 1");
        
        // Set piece to stepping stone phase 1 state
        piece.stepping_chain = 2;
        piece.extra_move_pending = true;
        piece.stepping_stone_instance = on_stone;
        piece.stone_original_x = on_stone.x;
        piece.stone_original_y = on_stone.y;
        piece.pre_stepping_x = piece.move_start_x;
        piece.pre_stepping_y = piece.move_start_y;
        
        // Force update piece's valid moves for 8-directional
        with (piece) {
            valid_moves = [];
            for (var dx = -1; dx <= 1; dx++) {
                for (var dy = -1; dy <= 1; dy++) {
                    if (dx != 0 || dy != 0) {
                        array_push(valid_moves, [dx, dy]);
                    }
                }
            }
        }
        
        // Get available 8-directional moves
        var phase1_moves = [];
        for (var i = 0; i < array_length(piece.valid_moves); i++) {
            var move = piece.valid_moves[i];
            var target_x = piece.x + move[0] * Board_Manager.tile_size;
            var target_y = piece.y + move[1] * Board_Manager.tile_size;
            
            // Check if target is on board and empty
            var tile = instance_place(target_x, target_y, Tile_Obj);
            if (tile && !instance_place(target_x, target_y, Chess_Piece_Obj)) {
                var move_data = {
                    piece: piece,
                    from_x: piece.x,
                    from_y: piece.y,
                    to_x: target_x,
                    to_y: target_y,
                    is_capture: false,
                    piece_id: piece.piece_id
                };
                array_push(phase1_moves, move_data);
            }
        }
        
        if (array_length(phase1_moves) > 0) {
            // Pick a random direction for phase 1
            var phase1_move = phase1_moves[irandom(array_length(phase1_moves) - 1)];
            
            // Execute phase 1 move
            piece.move_start_x = piece.x;
            piece.move_start_y = piece.y;
            piece.move_target_x = phase1_move.to_x;
            piece.move_target_y = phase1_move.to_y;
            piece.move_progress = 0;
            piece.move_duration = 30;
            piece.is_moving = true;
            piece.move_animation_type = "linear";
            
            // Move the stepping stone with the piece
            if (instance_exists(on_stone)) {
                on_stone.move_start_x = on_stone.x;
                on_stone.move_start_y = on_stone.y;
                on_stone.move_target_x = phase1_move.to_x;
                on_stone.move_target_y = phase1_move.to_y;
                on_stone.move_progress = 0;
                on_stone.move_duration = 30;
                on_stone.is_moving = true;
            }
            
            AI_Manager.ai_stepping_phase = 2; // Move to phase 2
        } else {
            // No valid phase 1 moves, end sequence
            AI_Manager.ai_stepping_phase = 0;
            AI_Manager.ai_stepping_piece = noone;
            Game_Manager.turn = 0;
        }
        
    } else if (AI_Manager.ai_stepping_phase == 2) {
        // Phase 2: Normal piece move
        show_debug_message("AI: Stepping stone phase 2");
        
        // Set piece to stepping stone phase 2 state
        piece.stepping_chain = 1;
        
        // Restore normal moves for this piece type
        switch (piece.piece_id) {
            case "knight":
                piece.valid_moves = [[1,-2],[1,2],[-1,-2],[-1,2],[2,-1],[2,1],[-2,-1],[-2,1]];
                break;
            // Add other pieces as needed
            default:
                // Force piece to recalculate its moves
                with (piece) {
                    event_perform(ev_step, ev_step_normal);
                }
                break;
        }
        
        // Get legal moves for phase 2
        try {
            var phase2_moves = [];
            for (var i = 0; i < array_length(piece.valid_moves); i++) {
                var move = piece.valid_moves[i];
                var target_x = piece.x + move[0] * Board_Manager.tile_size;
                var target_y = piece.y + move[1] * Board_Manager.tile_size;
                
                var tile = instance_place(target_x, target_y, Tile_Obj);
                if (tile) {
                    var target_piece = instance_position(target_x, target_y, Chess_Piece_Obj);
                    var is_capture = (target_piece != noone && target_piece.piece_type != piece.piece_type);
                    var is_blocked = (target_piece != noone && target_piece.piece_type == piece.piece_type);
                    
                    if (!is_blocked) {
                        var move_data = {
                            piece: piece,
                            from_x: piece.x,
                            from_y: piece.y,
                            to_x: target_x,
                            to_y: target_y,
                            is_capture: is_capture,
                            captured_piece: is_capture ? target_piece : noone,
                            piece_id: piece.piece_id
                        };
                        array_push(phase2_moves, move_data);
                    }
                }
            }
            
            if (array_length(phase2_moves) > 0) {
                // Pick best phase 2 move
                var best_move = phase2_moves[0];
                var best_score = -999;
                
                for (var i = 0; i < array_length(phase2_moves); i++) {
                    var move = phase2_moves[i];
                    var score_ = ai_score_move_fast(move);
                    if (score_ > best_score) {
                        best_score = score_;
                        best_move = move;
                    }
                }
                
                // Execute phase 2 move
                if (best_move.is_capture && instance_exists(best_move.captured_piece)) {
                    instance_destroy(best_move.captured_piece);
                }
                
                piece.move_start_x = piece.x;
                piece.move_start_y = piece.y;
                piece.move_target_x = best_move.to_x;
                piece.move_target_y = best_move.to_y;
                piece.move_progress = 0;
                piece.move_duration = 30;
                piece.is_moving = true;
                piece.move_animation_type = (piece.piece_id == "knight") ? "knight" : "linear";
                piece.landing_sound = Piece_Landing_SFX;
                piece.landing_sound_pending = true;
                
                // Move stepping stone back to original position
                if (instance_exists(piece.stepping_stone_instance)) {
                    piece.stepping_stone_instance.move_start_x = piece.stepping_stone_instance.x;
                    piece.stepping_stone_instance.move_start_y = piece.stepping_stone_instance.y;
                    piece.stepping_stone_instance.move_target_x = piece.stone_original_x;
                    piece.stepping_stone_instance.move_target_y = piece.stone_original_y;
                    piece.stepping_stone_instance.move_progress = 0;
                    piece.stepping_stone_instance.move_duration = 30;
                    piece.stepping_stone_instance.is_moving = true;
                }
                
                // Clean up stepping stone state
                piece.stepping_chain = 0;
                piece.extra_move_pending = false;
                piece.stepping_stone_instance = noone;
                piece.pending_turn_switch = 0; // End AI turn after animation
                
                // End stepping stone sequence
                AI_Manager.ai_stepping_phase = 0;
                AI_Manager.ai_stepping_piece = noone;
            } else {
                // No valid phase 2 moves, end sequence
                piece.stepping_chain = 0;
                piece.extra_move_pending = false;
                piece.stepping_stone_instance = noone;
                AI_Manager.ai_stepping_phase = 0;
                AI_Manager.ai_stepping_piece = noone;
                Game_Manager.turn = 0;
            }
            
        } catch (error) {
            show_debug_message("AI Stepping Stone Error: " + string(error));
            AI_Manager.ai_stepping_phase = 0;
            AI_Manager.ai_stepping_piece = noone;
            Game_Manager.turn = 0;
        }
    }
	
	if (AI_Manager.ai_stepping_phase == 0) {
    // Stepping stone sequence complete - clean up piece state
    if (instance_exists(piece)) {
        piece.stepping_chain = 0;
        piece.extra_move_pending = false;
        piece.stepping_stone_instance = noone;
        piece.pending_turn_switch = 0; // NOW switch to player
        piece.pending_normal_move = false;
    }
    Game_Manager.selected_piece = noone;
    show_debug_message("AI stepping stone sequence complete - switching to player turn");
}
}