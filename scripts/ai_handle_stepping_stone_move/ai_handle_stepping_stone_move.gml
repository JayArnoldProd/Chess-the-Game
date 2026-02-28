/// @function ai_handle_stepping_stone_move()
/// @description Handles AI stepping stone sequence - FIXED VERSION
function ai_handle_stepping_stone_move() {
    var piece = AI_Manager.ai_stepping_piece;
    
    // Safety check
    if (!instance_exists(piece)) {
        show_debug_message("AI: Stepping stone piece no longer exists, ending sequence");
        ai_end_stepping_stone_sequence();
        return;
    }
    
    // Animation checks are now done in AI_Manager Step before calling this function
    
    if (AI_Manager.ai_stepping_phase == 1) {
        // Phase 1: 8-directional move from stepping stone
        show_debug_message("AI: Stepping stone phase 1 - executing 8-directional move");
        
        // Verify stepping stone state was set up (by ai_execute_move_animated)
        var on_stone = piece.stepping_stone_instance;
        
        // If stone instance wasn't set, try to find it
        if (!instance_exists(on_stone)) {
            show_debug_message("AI: Stone instance not set, searching...");
            on_stone = instance_position(piece.x, piece.y, Stepping_Stone_Obj);
            if (!on_stone) {
                on_stone = instance_position(piece.x + Board_Manager.tile_size/4, piece.y + Board_Manager.tile_size/4, Stepping_Stone_Obj);
            }
            if (!on_stone) {
                with (Stepping_Stone_Obj) {
                    if (point_distance(x, y, piece.x, piece.y) < Board_Manager.tile_size) {
                        on_stone = id;
                        break;
                    }
                }
            }
            
            if (!on_stone) {
                show_debug_message("AI: No stone found at piece position, ending sequence");
                ai_end_stepping_stone_sequence();
                return;
            }
            
            // Set up the stone state that should have been set
            piece.stepping_stone_instance = on_stone;
            piece.stone_original_x = on_stone.x;
            piece.stone_original_y = on_stone.y;
        }
        
        show_debug_message("AI: Stone found at (" + string(on_stone.x) + "," + string(on_stone.y) + ")");
        
        // Ensure piece state is correct
        piece.stepping_chain = 2;
        piece.extra_move_pending = true;
        
        show_debug_message("AI: Generating 8-directional moves...");
        
        // Get available 8-directional moves
        var phase1_moves = [];
        for (var dx = -1; dx <= 1; dx++) {
            for (var dy = -1; dy <= 1; dy++) {
                if (dx == 0 && dy == 0) continue;
                
                var target_x = piece.x + dx * Board_Manager.tile_size;
                var target_y = piece.y + dy * Board_Manager.tile_size;
                
                show_debug_message("AI: Checking direction " + string(dx) + "," + string(dy) + " -> (" + string(target_x) + "," + string(target_y) + ")");
                
                // Check if target is on board - use instance_position with center offset for reliable detection
                var check_cx = target_x + Board_Manager.tile_size / 4;
                var check_cy = target_y + Board_Manager.tile_size / 4;
                var tile = instance_position(check_cx, check_cy, Tile_Obj);
                if (!tile) {
                    // Also try exact position and other offsets
                    tile = instance_position(target_x, target_y, Tile_Obj);
                }
                if (!tile) {
                    tile = instance_place(target_x, target_y, Tile_Obj);
                }
                if (!tile) {
                    show_debug_message("AI: No tile at target location");
                    continue;
                }
                
                // Check if target is empty (for stepping stone phase 1, only empty squares allowed)
                var blocking_piece = instance_position(check_cx, check_cy, Chess_Piece_Obj);
                if (blocking_piece == noone) {
                    blocking_piece = instance_position(target_x, target_y, Chess_Piece_Obj);
                }
                if (blocking_piece != noone && blocking_piece != piece) {
                    show_debug_message("AI: Square occupied by " + blocking_piece.piece_id);
                    continue;
                }
                
                // Can't hop stone-to-stone (prevents AI double stone stepping)
                var _other_stone = instance_position(check_cx, check_cy, Stepping_Stone_Obj);
                if (_other_stone == noone) _other_stone = instance_position(target_x, target_y, Stepping_Stone_Obj);
                if (_other_stone != noone && _other_stone != on_stone) {
                    show_debug_message("AI: Another stepping stone at target — skipping");
                    continue;
                }
                
                // Can't land on enemies
                var _enemy_check = instance_position(check_cx, check_cy, Enemy_Obj);
                if (_enemy_check != noone && !_enemy_check.is_dead) {
                    show_debug_message("AI: Enemy at target — skipping");
                    continue;
                }
                
                // Valid move found
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
                
                show_debug_message("AI: ✓ Valid phase1 move: " + string(dx) + "," + string(dy));
            }
        }
        
        show_debug_message("AI: Found " + string(array_length(phase1_moves)) + " phase1 moves");
        
        if (array_length(phase1_moves) > 0) {
            // Pick a good direction for phase 1
            var best_move = phase1_moves[0];
            var best_score = -999;
            
            for (var i = 0; i < array_length(phase1_moves); i++) {
                var move = phase1_moves[i];
                var score_ = 0;
                
                // Prefer moves toward center or toward enemy pieces
                var target_file = round((move.to_x - Object_Manager.topleft_x) / Board_Manager.tile_size);
                var target_rank = round((move.to_y - Object_Manager.topleft_y) / Board_Manager.tile_size);
                
                if (target_file >= 2 && target_file <= 5 && target_rank >= 2 && target_rank <= 5) {
                    score_ += 50; // Center bonus
                }
                
                // Prefer moves toward white pieces (enemy)
                with (Chess_Piece_Obj) {
                    if (piece_type == 0) { // White pieces
                        var distance = point_distance(move.to_x, move.to_y, x, y);
                        if (distance < Board_Manager.tile_size * 3) {
                            score_ += 25; // Get closer to enemy
                        }
                    }
                }
                
                score_ += irandom(30); // Some randomness
                
                if (score_ > best_score) {
                    best_score = score_;
                    best_move = move;
                }
            }
            
            show_debug_message("AI: Executing phase1 move to (" + string(best_move.to_x) + "," + string(best_move.to_y) + ")");
            
            // Execute phase 1 move
            piece.move_start_x = piece.x;
            piece.move_start_y = piece.y;
            piece.move_target_x = best_move.to_x;
            piece.move_target_y = best_move.to_y;
            piece.move_progress = 0;
            piece.move_duration = 30;
            piece.is_moving = true;
            piece.move_animation_type = "linear";
            
            // Move the stepping stone with the piece
            if (instance_exists(on_stone)) {
                on_stone.move_start_x = on_stone.x;
                on_stone.move_start_y = on_stone.y;
                on_stone.move_target_x = best_move.to_x;
                on_stone.move_target_y = best_move.to_y;
                on_stone.move_progress = 0;
                on_stone.move_duration = 30;
                on_stone.is_moving = true;
                
                show_debug_message("AI: Moving stone from (" + string(on_stone.move_start_x) + "," + string(on_stone.move_start_y) + ") to (" + string(on_stone.move_target_x) + "," + string(on_stone.move_target_y) + ")");
            }
            
            AI_Manager.ai_stepping_phase = 2; // Move to phase 2
            show_debug_message("AI: Advanced to phase 2");
            
        } else {
            // No valid phase 1 moves - try different approach
            show_debug_message("AI: No 8-directional moves found, checking if piece can move normally");
            
            // Force piece to use its normal valid moves (since it's in stepping stone mode)
            piece.stepping_chain = 1; // Switch to phase 2 mode
            with (piece) {
                event_perform(ev_step, ev_step_normal);
            }
            
            if (array_length(piece.valid_moves) > 0) {
                show_debug_message("AI: Found " + string(array_length(piece.valid_moves)) + " normal moves, skipping to phase 2");
                AI_Manager.ai_stepping_phase = 2; // Skip to phase 2
            } else {
                show_debug_message("AI: No moves available, ending sequence");
                ai_end_stepping_stone_sequence();
            }
        }
        
    } else if (AI_Manager.ai_stepping_phase == 2) {
        // Phase 2: Normal piece move
        show_debug_message("AI: Stepping stone phase 2 - making normal move");
        show_debug_message("AI: Piece " + piece.piece_id + " at (" + string(piece.x) + "," + string(piece.y) + ")");
        
        // Set piece to stepping stone phase 2 state
        piece.stepping_chain = 1;
        
        // Temporarily allow piece Step to run for AI by setting turn to a neutral value
        // Actually, just force recalculate valid_moves directly based on piece type
        // The piece's Step event skips AI pieces during AI turn, so we manually trigger move calc
        with (piece) {
            // Force the piece-specific Step to run by calling it
            event_perform(ev_step, ev_step_normal);
        }
        
        show_debug_message("AI: Piece has " + string(array_length(piece.valid_moves)) + " normal moves from Step event");
        
        // If valid_moves is empty, the piece Step may have been skipped for AI
        // Manually generate moves based on piece type
        if (array_length(piece.valid_moves) == 0) {
            show_debug_message("AI: valid_moves empty after Step - generating manually for " + piece.piece_id);
            // For phase 2, we need the piece's NORMAL movement pattern
            // This varies by piece type, so we use the same logic the piece objects use
            var _pid = piece.piece_id;
            if (_pid == "pawn") {
                // Pawns move forward (relative to their color) — only if square is EMPTY
                var _dir = (piece.piece_type == 1) ? 1 : -1; // black moves down (+y)
                piece.valid_moves = [];
                var _fx = piece.x;
                var _fy = piece.y + _dir * Board_Manager.tile_size;
                var _fp = instance_position(_fx, _fy, Chess_Piece_Obj);
                if (_fp == noone || _fp == piece) {
                    array_push(piece.valid_moves, [0, _dir]); // Forward only if empty
                }
                // Diagonal captures — only if enemy piece is there
                var _lx = piece.x + (-1) * Board_Manager.tile_size;
                var _rx = piece.x + (1) * Board_Manager.tile_size;
                var _lp = instance_position(_lx, _fy, Chess_Piece_Obj);
                if (_lp != noone && _lp != piece && _lp.piece_type != piece.piece_type) {
                    array_push(piece.valid_moves, [-1, _dir]);
                }
                var _rp = instance_position(_rx, _fy, Chess_Piece_Obj);
                if (_rp != noone && _rp != piece && _rp.piece_type != piece.piece_type) {
                    array_push(piece.valid_moves, [1, _dir]);
                }
            } else if (_pid == "knight") {
                piece.valid_moves = [[-2,-1],[-2,1],[-1,-2],[-1,2],[1,-2],[1,2],[2,-1],[2,1]];
            } else if (_pid == "bishop") {
                piece.valid_moves = [];
                var _dirs = [[-1,-1],[-1,1],[1,-1],[1,1]];
                for (var _d = 0; _d < 4; _d++) {
                    for (var _dist = 1; _dist <= 7; _dist++) {
                        var _mx = _dirs[_d][0] * _dist;
                        var _my = _dirs[_d][1] * _dist;
                        array_push(piece.valid_moves, [_mx, _my]);
                        var _cx = piece.x + _mx * Board_Manager.tile_size;
                        var _cy = piece.y + _my * Board_Manager.tile_size;
                        if (instance_position(_cx, _cy, Chess_Piece_Obj) != noone) break;
                        if (!instance_position(_cx + Board_Manager.tile_size/4, _cy + Board_Manager.tile_size/4, Tile_Obj)) break;
                    }
                }
            } else if (_pid == "rook") {
                piece.valid_moves = [];
                var _dirs = [[0,-1],[0,1],[-1,0],[1,0]];
                for (var _d = 0; _d < 4; _d++) {
                    for (var _dist = 1; _dist <= 7; _dist++) {
                        var _mx = _dirs[_d][0] * _dist;
                        var _my = _dirs[_d][1] * _dist;
                        array_push(piece.valid_moves, [_mx, _my]);
                        var _cx = piece.x + _mx * Board_Manager.tile_size;
                        var _cy = piece.y + _my * Board_Manager.tile_size;
                        if (instance_position(_cx, _cy, Chess_Piece_Obj) != noone) break;
                        if (!instance_position(_cx + Board_Manager.tile_size/4, _cy + Board_Manager.tile_size/4, Tile_Obj)) break;
                    }
                }
            } else if (_pid == "queen") {
                piece.valid_moves = [];
                var _dirs = [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]];
                for (var _d = 0; _d < 8; _d++) {
                    for (var _dist = 1; _dist <= 7; _dist++) {
                        var _mx = _dirs[_d][0] * _dist;
                        var _my = _dirs[_d][1] * _dist;
                        array_push(piece.valid_moves, [_mx, _my]);
                        var _cx = piece.x + _mx * Board_Manager.tile_size;
                        var _cy = piece.y + _my * Board_Manager.tile_size;
                        if (instance_position(_cx, _cy, Chess_Piece_Obj) != noone) break;
                        if (!instance_position(_cx + Board_Manager.tile_size/4, _cy + Board_Manager.tile_size/4, Tile_Obj)) break;
                    }
                }
            } else if (_pid == "king") {
                piece.valid_moves = [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]];
            }
            show_debug_message("AI: Manually generated " + string(array_length(piece.valid_moves)) + " moves for " + _pid);
        }
        
        // Get available moves for phase 2 (normal piece moves)
        try {
            var phase2_moves = [];
            for (var i = 0; i < array_length(piece.valid_moves); i++) {
                var move = piece.valid_moves[i];
                var target_x = piece.x + move[0] * Board_Manager.tile_size;
                var target_y = piece.y + move[1] * Board_Manager.tile_size;
                
                // Use instance_position with center offset for reliable tile detection
                var _tcx = target_x + Board_Manager.tile_size / 4;
                var _tcy = target_y + Board_Manager.tile_size / 4;
                var tile = instance_position(_tcx, _tcy, Tile_Obj);
                if (!tile) tile = instance_position(target_x, target_y, Tile_Obj);
                if (!tile) tile = instance_place(target_x, target_y, Tile_Obj);
                if (tile) {
                    var target_piece = instance_position(_tcx, _tcy, Chess_Piece_Obj);
                    if (target_piece == noone) target_piece = instance_position(target_x, target_y, Chess_Piece_Obj);
                    if (target_piece == piece) target_piece = noone; // Exclude self
                    
                    // Can't land on another stepping stone in phase 2 either
                    var _p2_stone = instance_position(_tcx, _tcy, Stepping_Stone_Obj);
                    if (_p2_stone == noone) _p2_stone = instance_position(target_x, target_y, Stepping_Stone_Obj);
                    if (_p2_stone != noone) {
                        show_debug_message("AI: Phase2 skip — stepping stone at target");
                        continue;
                    }
                    
                    // Pawn-specific rules: can only capture diagonally, forward must be empty
                    var is_capture = false;
                    if (piece.piece_id == "pawn") {
                        var _is_diagonal = (move[0] != 0); // diagonal if dx != 0
                        if (_is_diagonal && target_piece != noone && target_piece.piece_type != piece.piece_type) {
                            is_capture = true; // Pawn diagonal capture — valid
                        } else if (!_is_diagonal && target_piece != noone) {
                            continue; // Pawn forward blocked — skip this move entirely
                        }
                        // else: pawn forward to empty square — valid non-capture
                    } else {
                        is_capture = (target_piece != noone && target_piece.piece_type != piece.piece_type);
                    }
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
                            piece_id: piece.piece_id,
                            piece_type: piece.piece_type
                        };
                        array_push(phase2_moves, move_data);
                        
                        show_debug_message("AI: Phase2 move option to (" + string(target_x) + "," + string(target_y) + ")" + (is_capture ? " [CAPTURE]" : ""));
                    }
                }
            }
            
            show_debug_message("AI: Found " + string(array_length(phase2_moves)) + " phase2 moves");
            
            if (array_length(phase2_moves) > 0) {
                // Pick best phase 2 move using safe move logic
                var best_move = ai_pick_safe_move(phase2_moves);
                
                if (best_move != undefined && instance_exists(best_move.piece)) {
                    show_debug_message("AI: Executing phase2 move to (" + string(best_move.to_x) + "," + string(best_move.to_y) + ")");
                    
                    // Execute phase 2 move
                    if (best_move.is_capture && instance_exists(best_move.captured_piece)) {
                        var _cap_name = best_move.captured_piece.piece_id;
                        instance_destroy(best_move.captured_piece);
                        audio_play_sound_on(piece.audio_emitter, Piece_Capture_SFX, 0, false);
                        show_debug_message("AI: Captured " + _cap_name);
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
                        show_debug_message("AI: Returning stone to (" + string(piece.stone_original_x) + "," + string(piece.stone_original_y) + ")");
                        
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
                    piece.pending_normal_move = true; // Process as normal move
                    
                    // End stepping stone sequence
                    AI_Manager.ai_stepping_phase = 0;
                    AI_Manager.ai_stepping_piece = noone;
                    
                    show_debug_message("AI: Stepping stone sequence complete!");
                } else {
                    // No valid phase 2 moves
                    show_debug_message("AI: No valid phase2 moves, ending sequence");
                    ai_end_stepping_stone_sequence();
                }
            } else {
                // No valid phase 2 moves
                show_debug_message("AI: No phase2 moves available, ending sequence");
                ai_end_stepping_stone_sequence();
            }
            
        } catch (error) {
            show_debug_message("AI Stepping Stone Error: " + string(error));
            ai_end_stepping_stone_sequence();
        }
    }
}