/// @file ai_world_effects.gml
/// @description Extensible world mechanics system for AI simulation
/// 
/// ARCHITECTURE:
/// - Each world mechanic implements a standard interface
/// - World effects are applied after each virtual move
/// - Evaluation bonuses are pluggable per world
/// - New mechanics can be added without modifying core search code

//=============================================================================
// WORLD TYPES & DETECTION
//=============================================================================

/// @function ai_get_current_world()
/// @returns {string} Current world identifier
function ai_get_current_world() {
    switch (room) {
        case Ruined_Overworld: return "ruined_overworld";
        case Pirate_Seas: return "pirate_seas";
        case Fear_Factory: return "fear_factory";
        case Twisted_Carnival: return "twisted_carnival";
        case Volcanic_Wasteland: 
        case Volcanic_Wasteland_Boss: return "volcanic_wasteland";
        case Void_Dimension: return "void_dimension";
        default: return "standard";
    }
}

/// @function ai_get_world_mechanics(world)
/// @returns {array} Array of mechanic identifiers active in this world
function ai_get_world_mechanics(_world) {
    switch (_world) {
        case "ruined_overworld":
            return ["stepping_stones"];
        case "pirate_seas":
            return ["water", "bridges"];
        case "fear_factory":
            return ["conveyors", "void_tiles"];
        case "twisted_carnival":
            return ["random_spawns"];
        case "volcanic_wasteland":
            return ["lava_hazards"];
        case "void_dimension":
            return ["void_tiles", "reduced_board"];
        default:
            return [];
    }
}

//=============================================================================
// VIRTUAL WORLD STATE
//=============================================================================

/// @function ai_build_virtual_world()
/// @returns {struct} Complete virtual world state including board, tiles, and objects
function ai_build_virtual_world() {
    var _world = ai_get_current_world();
    
    // Build base board
    var _board = array_create(8);
    for (var row = 0; row < 8; row++) {
        _board[row] = array_create(8, noone);
    }
    
    // Build tile map (for water, void, etc.)
    var _tiles = array_create(8);
    for (var row = 0; row < 8; row++) {
        _tiles[row] = array_create(8, 0); // 0 = normal, 1 = water, -1 = void
    }
    
    // Populate pieces
    with (Chess_Piece_Obj) {
        if (!instance_exists(id)) continue;
        var bx = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        var by = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        if (bx >= 0 && bx < 8 && by >= 0 && by < 8) {
            _board[by][bx] = {
                piece_id: piece_id,
                piece_type: piece_type,
                has_moved: has_moved,
                health: variable_instance_exists(id, "health_") ? health_ : 1,
                stepping_chain: stepping_chain,
                instance: id
            };
        }
    }
    
    // Populate tile types
    with (Tile_Obj) {
        var bx = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        var by = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        if (bx >= 0 && bx < 8 && by >= 0 && by < 8) {
            _tiles[by][bx] = tile_type;
        }
    }
    
    // Build world objects map
    var _objects = {
        stepping_stones: [],
        bridges: [],
        conveyors: []
    };
    
    // Stepping stones
    with (Stepping_Stone_Obj) {
        var bx = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        var by = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        if (bx >= 0 && bx < 8 && by >= 0 && by < 8) {
            array_push(_objects.stepping_stones, { col: bx, row: by, instance: id });
        }
    }
    
    // Bridges
    with (Bridge_Obj) {
        var bx = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        var by = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        if (bx >= 0 && bx < 8 && by >= 0 && by < 8) {
            array_push(_objects.bridges, { col: bx, row: by });
        }
    }
    
    // Factory Droppers (trash cans) - mark as void in tile map
    with (Factory_Dropper_Obj) {
        var bx = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        var by = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        if (bx >= 0 && bx < 8 && by >= 0 && by < 8) {
            _tiles[by][bx] = -1; // Treat droppers as void tiles
            // Factory_Dropper marked as void in tile map
        }
    }
    
    // Conveyors - store belt info
    with (Factory_Belt_Obj) {
        var bx = round((x - Object_Manager.topleft_x) / Board_Manager.tile_size);
        var by = round((y - Object_Manager.topleft_y) / Board_Manager.tile_size);
        // Note: right_direction=true means pieces move RIGHT (+x)  
        // direction: 1 = pieces move right, -1 = pieces move left
        
        // Get actual belt length from total_tiles (don't hardcode!)
        var _actual_length = variable_instance_exists(id, "total_tiles") ? total_tiles : 6;
        
        var _belt_info = {
            start_col: bx,
            row: by,
            length: _actual_length,
            direction: variable_instance_exists(id, "right_direction") ? (right_direction ? 1 : -1) : 1
        };
        array_push(_objects.conveyors, _belt_info);
    }
    
    var _result = {
        world: _world,
        mechanics: ai_get_world_mechanics(_world),
        board: _board,
        tiles: _tiles,
        objects: _objects,
        turn_count: 0  // For turn-based effects
    };
    
    // Diagnostics stripped for performance (were used to debug dropper/void detection)
    
    return _result;
}

//=============================================================================
// WORLD EFFECT APPLICATION (Called after each virtual move)
//=============================================================================

/// @function ai_apply_world_effects(world_state)
/// @param {struct} world_state The virtual world state (modified in place)
/// @description Applies all active world mechanics after a move
function ai_apply_world_effects(_world_state) {
    var _mechanics = _world_state.mechanics;
    
    for (var i = 0; i < array_length(_mechanics); i++) {
        switch (_mechanics[i]) {
            case "conveyors":
                ai_apply_conveyor_effect(_world_state);
                break;
            case "water":
                ai_apply_water_effect(_world_state);
                break;
            case "void_tiles":
                ai_apply_void_effect(_world_state);
                break;
            case "lava_hazards":
                ai_apply_lava_effect(_world_state);
                break;
            case "stepping_stones":
                // Stepping stones don't have passive effects - handled during move gen
                break;
            case "random_spawns":
                // Can't predict random spawns - account for in evaluation instead
                break;
        }
    }
    
    _world_state.turn_count++;
}

/// @function ai_apply_conveyor_effect(world_state)
/// @description Shifts pieces on conveyor belts (checks tile hazards at destination)
function ai_apply_conveyor_effect(_world_state) {
    var _board = _world_state.board;
    var _tiles = _world_state.tiles;
    var _conveyors = _world_state.objects.conveyors;
    
    for (var c = 0; c < array_length(_conveyors); c++) {
        var _belt = _conveyors[c];
        var _row = _belt.row;
        var _start = _belt.start_col;
        var _len = _belt.length;
        var _dir = _belt.direction; // 1 = right, -1 = left
        
        if (_row < 0 || _row >= 8) continue;
        
        // Find pieces on this belt and shift them
        if (_dir > 0) {
            // Moving right - process from right to left to avoid overwriting
            for (var col = _start + _len - 1; col >= _start; col--) {
                if (col < 0 || col >= 8) continue;
                var _piece = _board[_row][col];
                if (_piece != noone) {
                    var _new_col = col + 1;
                    _board[_row][col] = noone;
                    if (_new_col >= 0 && _new_col < 8) {
                        var _dest_tile = _tiles[_row][_new_col];
                        if (_dest_tile != -1) {
                            _board[_row][_new_col] = _piece;
                        }
                        // else: void/trash — piece destroyed
                    }
                    // else: off board — piece destroyed
                }
            }
        } else {
            // Moving left - process from left to right
            for (var col = _start; col < _start + _len; col++) {
                if (col < 0 || col >= 8) continue;
                var _piece = _board[_row][col];
                if (_piece != noone) {
                    var _new_col = col - 1;
                    _board[_row][col] = noone;
                    if (_new_col >= 0 && _new_col < 8) {
                        var _dest_tile = _tiles[_row][_new_col];
                        if (_dest_tile != -1) {
                            _board[_row][_new_col] = _piece;
                        }
                        // else: void/trash — piece destroyed
                    }
                    // else: off board — piece destroyed
                }
            }
        }
    }
}

/// @function ai_apply_water_effect(world_state)
/// @description Destroys pieces on water tiles without bridges
function ai_apply_water_effect(_world_state) {
    var _board = _world_state.board;
    var _tiles = _world_state.tiles;
    var _bridges = _world_state.objects.bridges;
    
    for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 8; col++) {
            if (_tiles[row][col] == 1 && _board[row][col] != noone) {
                // Check for bridge
                var _has_bridge = false;
                for (var b = 0; b < array_length(_bridges); b++) {
                    if (_bridges[b].col == col && _bridges[b].row == row) {
                        _has_bridge = true;
                        break;
                    }
                }
                if (!_has_bridge) {
                    _board[row][col] = noone; // Piece drowns
                }
            }
        }
    }
}

/// @function ai_apply_void_effect(world_state)
/// @description Destroys pieces on void tiles
function ai_apply_void_effect(_world_state) {
    var _board = _world_state.board;
    var _tiles = _world_state.tiles;
    
    for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 8; col++) {
            if (_tiles[row][col] == -1 && _board[row][col] != noone) {
                _board[row][col] = noone; // Piece destroyed
            }
        }
    }
}

/// @function ai_apply_lava_effect(world_state)
/// @description Applies lava damage to pieces (same as void for now)
function ai_apply_lava_effect(_world_state) {
    // For now, treat lava same as void
    // Future: Could do damage over time with HP system
    ai_apply_void_effect(_world_state);
}

//=============================================================================
// WORLD-AWARE MOVE VALIDATION
//=============================================================================

/// @function ai_is_tile_safe(world_state, col, row, color)
/// @returns {bool} Whether a piece can safely move to this tile
function ai_is_tile_safe(_world_state, _col, _row, _color) {
    if (_row < 0 || _row >= 8 || _col < 0 || _col >= 8) return false;
    
    var _tile_type = _world_state.tiles[_row][_col];
    
    // Void tiles are never safe
    if (_tile_type == -1) return false;
    
    // Water tiles need bridges
    if (_tile_type == 1) {
        var _bridges = _world_state.objects.bridges;
        for (var b = 0; b < array_length(_bridges); b++) {
            if (_bridges[b].col == _col && _bridges[b].row == _row) {
                return true; // Has bridge
            }
        }
        return false; // No bridge = drowning
    }
    
    // NOTE: Conveyor danger is NOT checked here anymore.
    // The search tree handles conveyor effects via ai_apply_board_world_effects()
    // after each virtual move, and ai_eval_conveyor_position_bonus() penalizes
    // dangerous positions. Blocking moves here was too aggressive — it prevented
    // pieces on belts from moving to adjacent belt tiles to escape, leaving them
    // stuck with no legal moves while the belt pushed them to their death.
    
    return true;
}

/// @function ai_is_on_stepping_stone(world_state, col, row)
/// @returns {bool} Whether there's a stepping stone at this position
function ai_is_on_stepping_stone(_world_state, _col, _row) {
    var _stones = _world_state.objects.stepping_stones;
    for (var i = 0; i < array_length(_stones); i++) {
        if (_stones[i].col == _col && _stones[i].row == _row) {
            return true;
        }
    }
    return false;
}

/// @function ai_is_on_conveyor(world_state, col, row)
/// @returns {struct|noone} Conveyor info if on one, noone otherwise
function ai_is_on_conveyor(_world_state, _col, _row) {
    var _conveyors = _world_state.objects.conveyors;
    for (var c = 0; c < array_length(_conveyors); c++) {
        var _belt = _conveyors[c];
        if (_row == _belt.row && _col >= _belt.start_col && _col < _belt.start_col + _belt.length) {
            return _belt;
        }
    }
    return noone;
}

//=============================================================================
// WORLD-AWARE EVALUATION BONUSES
//=============================================================================

/// @function ai_evaluate_world_bonuses(world_state, color)
/// @returns {real} Additional score based on world mechanics
function ai_evaluate_world_bonuses(_world_state, _color) {
    var _score = 0;
    var _mechanics = _world_state.mechanics;
    
    for (var i = 0; i < array_length(_mechanics); i++) {
        switch (_mechanics[i]) {
            case "stepping_stones":
                _score += ai_eval_stepping_stone_bonus(_world_state, _color);
                break;
            case "water":
            case "bridges":
                _score += ai_eval_bridge_control_bonus(_world_state, _color);
                break;
            case "conveyors":
                _score += ai_eval_conveyor_position_bonus(_world_state, _color);
                break;
            case "void_tiles":
                _score += ai_eval_void_avoidance_bonus(_world_state, _color);
                break;
            case "random_spawns":
                _score += ai_eval_spawn_volatility_bonus(_world_state, _color);
                break;
        }
    }
    
    return _score;
}

/// @function ai_eval_stepping_stone_bonus(world_state, color)
function ai_eval_stepping_stone_bonus(_world_state, _color) {
    var _score = 0;
    var _board = _world_state.board;
    var _stones = _world_state.objects.stepping_stones;
    
    // Bonus for pieces near stepping stones (mobility bonus)
    for (var s = 0; s < array_length(_stones); s++) {
        var _stone = _stones[s];
        // Check if our piece is on or adjacent to the stone
        for (var dy = -1; dy <= 1; dy++) {
            for (var dx = -1; dx <= 1; dx++) {
                var _r = _stone.row + dy;
                var _c = _stone.col + dx;
                if (_r >= 0 && _r < 8 && _c >= 0 && _c < 8) {
                    var _piece = _board[_r][_c];
                    if (_piece != noone) {
                        var _sign = (_piece.piece_type == _color) ? 1 : -1;
                        if (dx == 0 && dy == 0) {
                            _score += _sign * 50; // On stone = big bonus
                        } else {
                            _score += _sign * 10; // Adjacent = small bonus
                        }
                    }
                }
            }
        }
    }
    
    return _score;
}

/// @function ai_eval_bridge_control_bonus(world_state, color)
function ai_eval_bridge_control_bonus(_world_state, _color) {
    var _score = 0;
    var _board = _world_state.board;
    var _bridges = _world_state.objects.bridges;
    
    // Bonus for controlling bridges
    for (var b = 0; b < array_length(_bridges); b++) {
        var _bridge = _bridges[b];
        var _piece = _board[_bridge.row][_bridge.col];
        if (_piece != noone) {
            var _sign = (_piece.piece_type == _color) ? 1 : -1;
            _score += _sign * 40; // Bridge control is valuable
        }
    }
    
    // Penalty for pieces that could be pushed into water
    // (Simplified - full analysis would check piece paths)
    
    return _score;
}

/// @function ai_eval_conveyor_position_bonus(world_state, color)
function ai_eval_conveyor_position_bonus(_world_state, _color) {
    var _score = 0;
    var _board = _world_state.board;
    var _conveyors = _world_state.objects.conveyors;
    var _tiles = _world_state.tiles;
    
    for (var c = 0; c < array_length(_conveyors); c++) {
        var _belt = _conveyors[c];
        var _row = _belt.row;
        var _dir = _belt.direction; // 1 = pieces pushed right, -1 = pushed left
        var _start = _belt.start_col;
        var _end = _belt.start_col + _belt.length - 1; // last belt column
        
        for (var col = _start; col <= _end; col++) {
            if (col < 0 || col >= 8) continue;
            var _piece = _board[_row][col];
            if (_piece == noone) continue;
            
            var _sign = (_piece.piece_type == _color) ? 1 : -1;
            var _piece_value = ai_get_piece_value_simple(_piece.piece_id);
            
            // Calculate how many turns until this piece falls off the belt exit
            var _turns_to_exit;
            if (_dir > 0) {
                // Belt pushes right — exit is past the right end
                _turns_to_exit = _end - col + 1; // +1 because push past _end falls off
            } else {
                // Belt pushes left — exit is past the left end
                _turns_to_exit = col - _start + 1;
            }
            
            // Check what's beyond the belt exit (is it a hazard?)
            var _exit_col = (_dir > 0) ? _end + 1 : _start - 1;
            var _exit_is_hazard = false;
            if (_exit_col < 0 || _exit_col >= 8) {
                _exit_is_hazard = true; // Off-board
            } else {
                var _exit_tile = _tiles[_row][_exit_col];
                if (_exit_tile == -1) _exit_is_hazard = true; // Void
                if (_exit_tile == 1) {
                    // Water — check for bridge
                    var _has_bridge = false;
                    var _bridges = _world_state.objects.bridges;
                    for (var b = 0; b < array_length(_bridges); b++) {
                        if (_bridges[b].col == _exit_col && _bridges[b].row == _row) {
                            _has_bridge = true;
                            break;
                        }
                    }
                    if (!_has_bridge) _exit_is_hazard = true;
                }
            }
            
            if (_exit_is_hazard) {
                // Heavy penalty scaled by piece value and urgency (fewer turns = more danger)
                // 1 turn away: lose full piece value equivalent
                // 2 turns: lose 75%
                // 3 turns: lose 50%
                // 4+ turns: minor penalty
                var _danger;
                if (_turns_to_exit <= 1) {
                    _danger = _piece_value; // About to die — equivalent to losing the piece
                } else if (_turns_to_exit <= 2) {
                    _danger = floor(_piece_value * 0.75);
                } else if (_turns_to_exit <= 3) {
                    _danger = floor(_piece_value * 0.50);
                } else {
                    _danger = floor(_piece_value * 0.25);
                }
                _score -= _sign * _danger;
            } else {
                // Belt pushes to a safe tile — minor instability penalty
                _score -= _sign * 10;
            }
            
            // General penalty for being on conveyor (unpredictable position)
            _score -= _sign * 15;
        }
    }
    
    return _score;
}

/// @function ai_eval_void_avoidance_bonus(world_state, color)
function ai_eval_void_avoidance_bonus(_world_state, _color) {
    var _score = 0;
    var _board = _world_state.board;
    var _tiles = _world_state.tiles;
    
    // Penalize pieces adjacent to void tiles (one wrong move = death)
    for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 8; col++) {
            var _piece = _board[row][col];
            if (_piece == noone) continue;
            
            var _sign = (_piece.piece_type == _color) ? 1 : -1;
            var _void_adjacent = 0;
            
            // Check adjacent tiles for void
            for (var dy = -1; dy <= 1; dy++) {
                for (var dx = -1; dx <= 1; dx++) {
                    if (dx == 0 && dy == 0) continue;
                    var _r = row + dy;
                    var _c = col + dx;
                    if (_r >= 0 && _r < 8 && _c >= 0 && _c < 8) {
                        if (_tiles[_r][_c] == -1) {
                            _void_adjacent++;
                        }
                    }
                }
            }
            
            // Penalty for being near void (especially for valuable pieces)
            if (_void_adjacent > 0) {
                var _piece_value = ai_get_piece_value_simple(_piece.piece_id);
                _score -= _sign * (_void_adjacent * 5) * (_piece_value / 100);
            }
        }
    }
    
    return _score;
}

/// @function ai_eval_spawn_volatility_bonus(world_state, color)
function ai_eval_spawn_volatility_bonus(_world_state, _color) {
    // Carnival: random pawn spawns make the board volatile
    // Favor controlling central squares, penalize isolated pieces
    var _score = 0;
    var _board = _world_state.board;
    
    for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 8; col++) {
            var _piece = _board[row][col];
            if (_piece == noone) continue;
            
            var _sign = (_piece.piece_type == _color) ? 1 : -1;
            
            // Bonus for central control (more options when pawns spawn)
            if (col >= 2 && col <= 5 && row >= 2 && row <= 5) {
                _score += _sign * 15;
            }
            
            // Count nearby friendly pieces (safety in numbers)
            var _friends = 0;
            for (var dy = -1; dy <= 1; dy++) {
                for (var dx = -1; dx <= 1; dx++) {
                    if (dx == 0 && dy == 0) continue;
                    var _r = row + dy;
                    var _c = col + dx;
                    if (_r >= 0 && _r < 8 && _c >= 0 && _c < 8) {
                        var _adj = _board[_r][_c];
                        if (_adj != noone && _adj.piece_type == _piece.piece_type) {
                            _friends++;
                        }
                    }
                }
            }
            
            // Bonus for having nearby support
            _score += _sign * (_friends * 5);
        }
    }
    
    return _score;
}

/// @function ai_get_piece_value_simple(piece_id)
function ai_get_piece_value_simple(_piece_id) {
    switch (_piece_id) {
        case "pawn": return 100;
        case "knight": return 320;
        case "bishop": return 330;
        case "rook": return 500;
        case "queen": return 900;
        case "king": return 20000;
        default: return 100;
    }
}

//=============================================================================
// DATA-DRIVEN PIECE MOVEMENT PATTERNS
//=============================================================================

/// @function ai_get_piece_movement_pattern(piece_id)
/// @returns {struct} Movement pattern definition for this piece type
/// @description Returns data-driven movement pattern instead of hardcoded switch
function ai_get_piece_movement_pattern(_piece_id) {
    // Movement patterns define how a piece can move
    // Types: "step" (single move), "slide" (until blocked), "leap" (jump over)
    
    switch (_piece_id) {
        case "pawn":
            // Pawns are special - handled separately due to direction/capture rules
            return {
                type: "pawn",
                directions: [], // Handled specially
                special: ["double_first", "en_passant", "promotion"]
            };
            
        case "knight":
            return {
                type: "leap",
                offsets: [[1,-2], [2,-1], [2,1], [1,2], [-1,2], [-2,1], [-2,-1], [-1,-2]],
                special: []
            };
            
        case "bishop":
            return {
                type: "slide",
                directions: [[1,-1], [1,1], [-1,1], [-1,-1]],
                special: []
            };
            
        case "rook":
            return {
                type: "slide",
                directions: [[0,-1], [1,0], [0,1], [-1,0]],
                special: []
            };
            
        case "queen":
            return {
                type: "slide",
                directions: [[0,-1], [1,-1], [1,0], [1,1], [0,1], [-1,1], [-1,0], [-1,-1]],
                special: []
            };
            
        case "king":
            return {
                type: "step",
                offsets: [[0,-1], [1,-1], [1,0], [1,1], [0,1], [-1,1], [-1,0], [-1,-1]],
                special: ["castle_k", "castle_q"]
            };
            
        default:
            // Unknown piece - no movement
            return {
                type: "none",
                directions: [],
                special: []
            };
    }
}

/// @function ai_register_custom_piece(piece_id, pattern)
/// @description Registers a custom piece type with its movement pattern
/// @param {string} piece_id Unique identifier for the piece
/// @param {struct} pattern Movement pattern struct
function ai_register_custom_piece(_piece_id, _pattern) {
    // Store in global registry for custom pieces
    if (!variable_global_exists("custom_piece_patterns")) {
        global.custom_piece_patterns = {};
    }
    global.custom_piece_patterns[$ _piece_id] = _pattern;
}

/// @function ai_get_movement_pattern(piece_id)
/// @description Gets movement pattern, checking custom pieces first
function ai_get_movement_pattern(_piece_id) {
    // Check custom pieces first
    if (variable_global_exists("custom_piece_patterns")) {
        if (variable_struct_exists(global.custom_piece_patterns, _piece_id)) {
            return global.custom_piece_patterns[$ _piece_id];
        }
    }
    // Fall back to standard pieces
    return ai_get_piece_movement_pattern(_piece_id);
}

//=============================================================================
// WORLD-AWARE MOVE GENERATION
//=============================================================================

/// @function ai_generate_moves_world_aware(board, color)
/// @description Generates legal moves with world mechanic awareness
function ai_generate_moves_world_aware(_board, _color) {
    // Get base legal moves
    var _moves = ai_generate_moves_from_board(_board, _color);
    
    // If no world state, return base moves
    if (!variable_global_exists("ai_current_world_state")) {
        return _moves;
    }
    
    var _world = global.ai_current_world_state;
    
    // Filter out moves to unsafe tiles (water without bridge, void)
    var _safe_moves = [];
    for (var i = 0; i < array_length(_moves); i++) {
        var _move = _moves[i];
        
        // Check if destination tile is safe
        if (ai_is_tile_safe(_world, _move.to_col, _move.to_row, _color)) {
            array_push(_safe_moves, _move);
        }
    }
    
    return _safe_moves;
}

/// @function ai_apply_board_world_effects(board, world_state)
/// @description Applies world effects to a board (simplified version for search)
function ai_apply_board_world_effects(_board, _world_state) {
    var _mechanics = _world_state.mechanics;
    
    for (var i = 0; i < array_length(_mechanics); i++) {
        switch (_mechanics[i]) {
            case "conveyors":
                ai_apply_conveyor_to_board(_board, _world_state.objects.conveyors, _world_state.tiles);
                break;
            case "water":
                ai_apply_water_to_board(_board, _world_state.tiles, _world_state.objects.bridges);
                break;
            case "void_tiles":
                ai_apply_void_to_board(_board, _world_state.tiles);
                break;
        }
    }
}

/// @function ai_apply_conveyor_to_board(board, conveyors, tiles)
/// @description Shifts pieces on conveyor belts. Pieces pushed off belt or onto hazards are destroyed.
function ai_apply_conveyor_to_board(_board, _conveyors, _tiles) {
    for (var c = 0; c < array_length(_conveyors); c++) {
        var _belt = _conveyors[c];
        var _row = _belt.row;
        var _start = _belt.start_col;
        var _len = _belt.length;
        var _dir = _belt.direction;
        
        if (_row < 0 || _row >= 8) continue;
        
        if (_dir > 0) {
            // Moving right — process from right to left to avoid overwriting
            for (var col = _start + _len - 1; col >= _start; col--) {
                if (col < 0 || col >= 8) continue;
                var _piece = _board[_row][col];
                if (_piece != noone) {
                    var _new_col = col + 1;
                    _board[_row][col] = noone; // Remove from current position
                    if (_new_col >= 0 && _new_col < 8) {
                        // Check if destination is a hazard
                        var _dest_tile = (_tiles != undefined && _row >= 0 && _row < 8) ? _tiles[_row][_new_col] : 0;
                        if (_dest_tile == -1) {
                            // Void/trash — piece destroyed
                        } else {
                            _board[_row][_new_col] = _piece; // Piece survives
                        }
                    }
                    // else: pushed off board — piece destroyed
                }
            }
        } else {
            // Moving left — process from left to right
            for (var col = _start; col < _start + _len; col++) {
                if (col < 0 || col >= 8) continue;
                var _piece = _board[_row][col];
                if (_piece != noone) {
                    var _new_col = col - 1;
                    _board[_row][col] = noone; // Remove from current position
                    if (_new_col >= 0 && _new_col < 8) {
                        var _dest_tile = (_tiles != undefined && _row >= 0 && _row < 8) ? _tiles[_row][_new_col] : 0;
                        if (_dest_tile == -1) {
                            // Void/trash — piece destroyed
                        } else {
                            _board[_row][_new_col] = _piece;
                        }
                    }
                    // else: pushed off board — piece destroyed
                }
            }
        }
    }
}

/// @function ai_apply_water_to_board(board, tiles, bridges)
function ai_apply_water_to_board(_board, _tiles, _bridges) {
    for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 8; col++) {
            if (_tiles[row][col] == 1 && _board[row][col] != noone) {
                var _has_bridge = false;
                for (var b = 0; b < array_length(_bridges); b++) {
                    if (_bridges[b].col == col && _bridges[b].row == row) {
                        _has_bridge = true;
                        break;
                    }
                }
                if (!_has_bridge) {
                    _board[row][col] = noone; // Drowns
                }
            }
        }
    }
}

/// @function ai_apply_void_to_board(board, tiles)
function ai_apply_void_to_board(_board, _tiles) {
    for (var row = 0; row < 8; row++) {
        for (var col = 0; col < 8; col++) {
            if (_tiles[row][col] == -1 && _board[row][col] != noone) {
                _board[row][col] = noone; // Destroyed
            }
        }
    }
}

//=============================================================================
// WORLD-AWARE EVALUATION (Called from quiescence/leaf nodes)
//=============================================================================

/// @function ai_evaluate_with_world(board, color)
/// @description Full evaluation including world mechanics bonuses
function ai_evaluate_with_world(_board, _color) {
    // Base evaluation
    var _score = ai_evaluate_advanced(_board);
    
    // Add world-specific bonuses
    if (variable_global_exists("ai_current_world_state")) {
        var _world_bonus = ai_evaluate_world_bonuses(global.ai_current_world_state, _color);
        _score += _world_bonus;
    }
    
    return _score;
}
