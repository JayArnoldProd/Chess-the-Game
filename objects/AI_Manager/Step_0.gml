/// AI_Manager Step Event - MULTI-FRAME STATE MACHINE
if (!ai_enabled) exit;

// Don't move if game is over
if (instance_exists(Game_Manager) && Game_Manager.game_over) {
    ai_state = "idle";
    exit;
}

// Pause AI when settings menu is open
if (instance_exists(Game_Manager) && Game_Manager.settings_open) {
    exit;
}

// ========== STEPPING STONE HANDLING ==========
// Handle stepping stone sequences first - ALWAYS check this
if (ai_stepping_phase > 0) {
    show_debug_message("AI: In stepping stone phase " + string(ai_stepping_phase));
    
    // Safety: verify the stepping stone piece still exists
    if (!instance_exists(ai_stepping_piece)) {
        show_debug_message("AI: Stepping stone piece no longer exists - ending sequence");
        ai_stepping_phase = 0;
        ai_stepping_piece = noone;
        ai_state = "idle";
        Game_Manager.turn = 0; // Give turn to player
        exit;
    }
    
    // Wait for piece animation to complete before proceeding
    if (ai_stepping_piece.is_moving) {
        exit; // Keep waiting for animation
    }
    
    // Also wait for any stepping stone animations
    var stone_moving = false;
    with (Stepping_Stone_Obj) {
        if (is_moving) {
            stone_moving = true;
            break;
        }
    }
    if (stone_moving) {
        exit; // Keep waiting for stone animation
    }
    
    // Now handle the stepping stone move
    ai_handle_stepping_stone_move();
    exit; // Don't do normal moves during stepping stone sequence
}

// ========== STATE MACHINE ==========
switch (ai_state) {
    
    // ===== IDLE STATE =====
    case "idle":
        // Only start thinking when it's AI's turn
        if (Game_Manager.turn != 1) exit;
        
        // Don't start while pieces are still animating (wait for turn switch)
        var _any_moving = false;
        with (Chess_Piece_Obj) {
            if (is_moving) {
                _any_moving = true;
                break;
            }
        }
        if (_any_moving) exit;
        
        // Don't start while conveyor belts are still animating
        var _belt_moving = false;
        with (Factory_Belt_Obj) {
            if (animating) {
                _belt_moving = true;
                break;
            }
        }
        if (_belt_moving) exit;
        
        // Reset delay counter if not set
        if (!variable_instance_exists(id, "ai_move_delay")) ai_move_delay = 30;
        
        // Wait for any delay
        if (ai_move_delay > 0) {
            ai_move_delay--;
            exit;
        }
        
        // Transition to preparing state
        ai_state = "preparing";
        show_debug_message("AI: State -> PREPARING");
        break;
    
    // ===== PREPARING STATE =====
    case "preparing":
        // Don't start while pieces are animating
        var any_moving = false;
        with (Chess_Piece_Obj) {
            if (is_moving) {
                any_moving = true;
                break;
            }
        }
        if (any_moving) {
            show_debug_message("AI: Waiting for piece animations...");
            exit;
        }
        
        // Don't start while conveyor belts are still animating
        var belt_moving = false;
        with (Factory_Belt_Obj) {
            if (animating) {
                belt_moving = true;
                break;
            }
        }
        if (belt_moving) {
            show_debug_message("AI: Waiting for conveyor belt animation...");
            exit;
        }
        
        // Build virtual world state (board + tiles + objects)
        ai_search_world_state = ai_build_virtual_world();
        ai_search_board = ai_search_world_state.board;
        global.ai_current_world_state = ai_search_world_state;
        
        // Initialize TT if needed
        if (!variable_global_exists("tt_entries")) {
            ai_tt_init(16);
        }
        
        // Generate root moves (world-aware: filters water/void and check)
        ai_search_moves = ai_generate_moves_world_aware(ai_search_board, 1); // AI is black (1)
        
        if (array_length(ai_search_moves) == 0) {
            // Check if this is checkmate (AI king in check with no escapes) or stalemate
            var ai_in_check = ai_is_king_in_check_virtual(ai_search_board, 1);
            if (ai_in_check) {
                show_debug_message("AI: CHECKMATE! AI has no legal moves while in check.");
                // AI is checkmated - player wins
                if (instance_exists(Game_Manager)) {
                    Game_Manager.game_over = true;
                    Game_Manager.winner = 0; // White (player) wins
                    show_debug_message("AI: Setting game_over=true, winner=0 (player)");
                }
            } else {
                show_debug_message("AI: STALEMATE! AI has no legal moves but not in check.");
                // Stalemate - draw
                if (instance_exists(Game_Manager)) {
                    Game_Manager.game_over = true;
                    Game_Manager.winner = -1; // Draw
                }
            }
            ai_state = "idle";
            exit;
        }
        
        // If only one legal move, just play it
        if (array_length(ai_search_moves) == 1) {
            show_debug_message("AI: Only one legal move - playing immediately");
            ai_search_best_move = ai_search_moves[0];
            ai_search_best_score = 0;
            ai_last_search_depth = 0;
            ai_last_search_nodes = 0;
            ai_last_search_time = 0;
            ai_state = "executing";
            exit;
        }
        
        // Order root moves using TT hints
        var _hash = ai_compute_hash(ai_search_board);
        ai_search_moves = ai_order_root_moves(ai_search_moves, _hash);
        
        // Initialize search state
        ai_search_index = 0;
        ai_search_best_move = ai_search_moves[0];
        ai_search_best_score = -999999;
        ai_search_current_depth = 1;
        ai_search_nodes_total = 0;
        ai_search_start_time = get_timer(); // Microseconds
        ai_search_depth_scores = [];
        
        // Initialize global search state
        global.ai_search_start_time = ai_search_start_time / 1000; // Convert to ms
        global.ai_search_time_limit = ai_time_limit;
        global.ai_search_nodes = 0;
        global.ai_search_stop = false;
        global.ai_search_depth_completed = 0;
        
        show_debug_message("AI: State -> SEARCHING (moves: " + string(array_length(ai_search_moves)) + ", time limit: " + string(ai_time_limit) + "ms)");
        
        // Instant mode (difficulty 1): skip search entirely
        if (ai_time_limit == 0) {
            ai_search_best_move = ai_search_moves[0]; // Best by ordering (captures first)
            ai_last_search_depth = 0;
            ai_last_search_nodes = 0;
            ai_last_search_time = 0;
            ai_last_search_score = 0;
            ai_state = "executing";
            exit;
        }
        
        ai_state = "searching";
        break;
    
    // ===== SEARCHING STATE =====
    case "searching":
        var frame_start = get_timer();
        var frame_budget_us = ai_search_frame_budget * 1000; // Convert ms to microseconds
        var total_elapsed_ms = (get_timer() - ai_search_start_time) / 1000;
        
        // Check total time limit
        if (total_elapsed_ms >= ai_time_limit) {
            show_debug_message("AI: Time limit reached (" + string(floor(total_elapsed_ms)) + "ms)");
            ai_finalize_search();
            exit;
        }
        
        // Process root moves within frame budget
        while ((get_timer() - frame_start) < frame_budget_us) {
            // Re-check total time limit inside loop
            total_elapsed_ms = (get_timer() - ai_search_start_time) / 1000;
            if (total_elapsed_ms >= ai_time_limit) {
                ai_finalize_search();
                exit;
            }
            
            // Are we done with current depth?
            if (ai_search_index >= array_length(ai_search_moves)) {
                // Completed this depth
                global.ai_search_depth_completed = ai_search_current_depth;
                show_debug_message("AI: Depth " + string(ai_search_current_depth) + " complete, best score: " + string(ai_search_best_score) + ", nodes: " + string(global.ai_search_nodes));
                
                // Check for mate score (can stop early)
                if (abs(ai_search_best_score) > 90000) {
                    show_debug_message("AI: Mate found - stopping search");
                    ai_finalize_search();
                    exit;
                }
                
                // Increment depth
                ai_search_current_depth++;
                
                // Max depth reached?
                if (ai_search_current_depth > ai_search_max_depth) {
                    ai_finalize_search();
                    exit;
                }
                
                // Reorder moves - put best move first (improves pruning)
                if (ai_search_best_move != undefined) {
                    var new_order = [ai_search_best_move];
                    for (var i = 0; i < array_length(ai_search_moves); i++) {
                        if (ai_search_moves[i] != ai_search_best_move) {
                            array_push(new_order, ai_search_moves[i]);
                        }
                    }
                    ai_search_moves = new_order;
                }
                
                // Reset for new depth
                ai_search_index = 0;
                ai_search_best_score = -999999; // Reset for new depth iteration
                continue;
            }
            
            // Search one root move
            var move = ai_search_moves[ai_search_index];
            
            // Make move on copy of board
            var new_board = ai_copy_board(ai_search_board);
            ai_make_move_virtual(new_board, move);
            var _hash = ai_compute_hash(ai_search_board);
            var new_hash = ai_update_hash(_hash,
                move.from_row * 8 + move.from_col,
                move.to_row * 8 + move.to_col,
                {piece_id: move.piece_id, piece_type: move.piece_type},
                move.is_capture ? {piece_id: "pawn", piece_type: 0} : noone
            );
            
            // Get stepping stones for bonus
            var stones = ai_search_world_state.objects.stepping_stones;
            
            // Search with negamax
            var _alpha = -999999;
            var _beta = 999999;
            var _score;
            
            if (ai_search_index == 0) {
                // Full window for first move
                _score = -ai_negamax_ab(new_board, new_hash, ai_search_current_depth - 1, -_beta, -_alpha, false, stones);
            } else {
                // PVS: null window first
                _score = -ai_negamax_ab(new_board, new_hash, ai_search_current_depth - 1, -ai_search_best_score - 1, -ai_search_best_score, false, stones);
                if (_score > ai_search_best_score && _score < _beta) {
                    // Re-search with full window
                    _score = -ai_negamax_ab(new_board, new_hash, ai_search_current_depth - 1, -_beta, -_alpha, false, stones);
                }
            }
            
            // Stepping stone bonus at root
            for (var s = 0; s < array_length(stones); s++) {
                if (stones[s].col == move.to_col && stones[s].row == move.to_row) {
                    _score += 30;
                    break;
                }
            }
            
            // Track best
            if (_score > ai_search_best_score) {
                ai_search_best_score = _score;
                ai_search_best_move = move;
            }
            
            ai_search_index++;
            ai_search_nodes_total = global.ai_search_nodes;
        }
        
        // Frame budget exhausted - yield to let game loop run
        // (cursor movement, animations, etc. can now update)
        break;
    
    // ===== EXECUTING STATE =====
    case "executing":
        if (ai_search_best_move == undefined) {
            show_debug_message("AI: No best move found - falling back to heuristic");
            // Fallback to heuristic (ai_get_legal_moves_safe now properly filters illegal moves)
            var legal_moves = ai_get_legal_moves_safe(1);
            if (array_length(legal_moves) == 0) {
                // No legal moves - check for checkmate
                var ai_in_check = ai_is_king_in_check_simple(1);
                if (ai_in_check) {
                    show_debug_message("AI: CHECKMATE (fallback path)! No legal moves while in check.");
                    if (instance_exists(Game_Manager)) {
                        Game_Manager.game_over = true;
                        Game_Manager.winner = 0; // Player wins
                    }
                } else {
                    show_debug_message("AI: STALEMATE (fallback path)! No legal moves.");
                    if (instance_exists(Game_Manager)) {
                        Game_Manager.game_over = true;
                        Game_Manager.winner = -1; // Draw
                    }
                }
                ai_state = "idle";
                exit;
            }
            ai_search_best_move = ai_pick_safe_move(legal_moves);
            if (ai_search_best_move == undefined) {
                // ai_pick_safe_move returned undefined - shouldn't happen if legal_moves > 0
                show_debug_message("AI: ai_pick_safe_move returned undefined - using first legal move");
                ai_search_best_move = legal_moves[0];
            }
        }
        
        // Convert virtual move to real move if needed
        var real_move = ai_search_best_move;
        if (!variable_struct_exists(ai_search_best_move, "piece") || !instance_exists(ai_search_best_move.piece)) {
            real_move = ai_convert_virtual_move_to_real(ai_search_best_move);
        }
        
        if (real_move != undefined && instance_exists(real_move.piece)) {
            ai_execute_move_animated(real_move);
            show_debug_message("AI: Executed move - " + real_move.piece.piece_id + 
                " (depth " + string(ai_last_search_depth) + 
                ", score " + string(ai_last_search_score) + 
                ", " + string(ai_last_search_nodes) + " nodes in " + 
                string(ai_last_search_time) + "ms)");
        } else {
            show_debug_message("AI: Failed to execute move - skipping turn");
            Game_Manager.turn = 0;
        }
        
        ai_move_delay = 30;
        ai_state = "waiting_turn_switch";
        break;
    
    // ===== WAITING FOR TURN SWITCH =====
    case "waiting_turn_switch":
        // Don't go back to idle until the turn has actually switched to the player
        // This prevents the double-move bug where AI cycles back to idle->preparing->executing
        // before pending_turn_switch fires
        if (Game_Manager.turn == 1) {
            // Still AI's turn - wait for the piece's pending_turn_switch to fire
            // Safety timeout: if we've been waiting too long, force the switch
            if (!variable_instance_exists(id, "wait_turn_timer")) wait_turn_timer = 0;
            wait_turn_timer++;
            if (wait_turn_timer > 300) { // 5 seconds at 60fps
                show_debug_message("AI: SAFETY - forcing turn switch after timeout");
                Game_Manager.turn = 0;
                wait_turn_timer = 0;
                ai_state = "idle";
            }
            exit;
        }
        // Turn has switched to player - safe to go back to idle
        wait_turn_timer = 0;
        ai_state = "idle";
        break;
}

/// @function ai_finalize_search()
/// @description Finalizes search and transitions to executing state
function ai_finalize_search() {
    var total_time = (get_timer() - ai_search_start_time) / 1000;
    
    ai_last_search_time = floor(total_time);
    ai_last_search_depth = global.ai_search_depth_completed;
    ai_last_search_nodes = global.ai_search_nodes;
    ai_last_search_score = ai_search_best_score;
    
    show_debug_message("AI: Search finalized - depth " + string(ai_last_search_depth) + 
        ", score " + string(ai_last_search_score) + 
        ", " + string(ai_last_search_nodes) + " nodes in " + 
        string(ai_last_search_time) + "ms");
    
    ai_state = "executing";
}
