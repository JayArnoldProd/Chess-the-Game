/// @function ai_get_piece_moves_virtual(board, col, row, piece)
/// @param {array} board Virtual board state
/// @param {real} col Column (0-7)
/// @param {real} row Row (0-7)
/// @param {struct} piece The piece at this position
/// @returns {array} Array of moves for this piece
/// @description Generates moves for a single piece on the virtual board
function ai_get_piece_moves_virtual(board, col, row, piece) {
    var moves = [];
    var piece_id = piece.piece_id;
    var piece_type = piece.piece_type;
    
    switch (piece_id) {
        case "pawn":
            moves = ai_get_pawn_moves_virtual(board, col, row, piece_type);
            break;
        case "knight":
            moves = ai_get_knight_moves_virtual(board, col, row, piece_type);
            break;
        case "bishop":
            moves = ai_get_sliding_moves_virtual(board, col, row, piece_type, [[1,-1],[-1,-1],[1,1],[-1,1]]);
            break;
        case "rook":
            moves = ai_get_sliding_moves_virtual(board, col, row, piece_type, [[0,-1],[1,0],[0,1],[-1,0]]);
            break;
        case "queen":
            moves = ai_get_sliding_moves_virtual(board, col, row, piece_type, [[0,-1],[1,0],[0,1],[-1,0],[1,-1],[-1,-1],[1,1],[-1,1]]);
            break;
        case "king":
            moves = ai_get_king_moves_virtual(board, col, row, piece_type, piece.has_moved);
            break;
    }
    
    return moves;
}

/// @function ai_get_pawn_moves_virtual(board, col, row, piece_type)
/// @description Pawn move generation with water/void awareness
function ai_get_pawn_moves_virtual(board, col, row, piece_type) {
    var moves = [];
    var dir = (piece_type == 0) ? -1 : 1; // White moves up (-), black moves down (+)
    var start_row = (piece_type == 0) ? 6 : 1;
    
    // Get tile data for water/void checking
    var _tiles = undefined;
    var _bridges = undefined;
    if (variable_global_exists("ai_current_world_state") && global.ai_current_world_state != undefined) {
        _tiles = global.ai_current_world_state.tiles;
        _bridges = global.ai_current_world_state.objects.bridges;
    }
    
    // Forward one square
    var new_row = row + dir;
    if (new_row >= 0 && new_row < 8) {
        // Check if target tile is safe (not water without bridge, not void)
        var tile_safe = ai_is_tile_safe_for_move(_tiles, _bridges, col, new_row);
        
        if (board[new_row][col] == noone && tile_safe) {
            array_push(moves, {from_col: col, from_row: row, to_col: col, to_row: new_row, is_capture: false, special: ""});
            
            // Forward two squares from starting position
            if (row == start_row) {
                var two_row = row + (dir * 2);
                var tile_safe_2 = ai_is_tile_safe_for_move(_tiles, _bridges, col, two_row);
                if (two_row >= 0 && two_row < 8 && board[two_row][col] == noone && tile_safe_2) {
                    array_push(moves, {from_col: col, from_row: row, to_col: col, to_row: two_row, is_capture: false, special: "double_pawn"});
                }
            }
        }
    }
    
    // Diagonal captures
    for (var dc = -1; dc <= 1; dc += 2) {
        var cap_col = col + dc;
        var cap_row = row + dir;
        if (cap_col >= 0 && cap_col < 8 && cap_row >= 0 && cap_row < 8) {
            var target = board[cap_row][cap_col];
            var tile_safe = ai_is_tile_safe_for_move(_tiles, _bridges, cap_col, cap_row);
            if (target != noone && target.piece_type != piece_type && tile_safe) {
                array_push(moves, {from_col: col, from_row: row, to_col: cap_col, to_row: cap_row, is_capture: true, special: ""});
            }
        }
    }
    
    // Note: En passant would need additional game state tracking - simplified for now
    
    return moves;
}

/// @function ai_get_knight_moves_virtual(board, col, row, piece_type)
/// @description Knight move generation with water/void awareness
function ai_get_knight_moves_virtual(board, col, row, piece_type) {
    var moves = [];
    var offsets = [[1,-2],[2,-1],[2,1],[1,2],[-1,2],[-2,1],[-2,-1],[-1,-2]];
    
    // Get tile data for water/void checking
    var _tiles = undefined;
    var _bridges = undefined;
    if (variable_global_exists("ai_current_world_state") && global.ai_current_world_state != undefined) {
        _tiles = global.ai_current_world_state.tiles;
        _bridges = global.ai_current_world_state.objects.bridges;
    }
    
    for (var i = 0; i < 8; i++) {
        var new_col = col + offsets[i][0];
        var new_row = row + offsets[i][1];
        
        if (new_col >= 0 && new_col < 8 && new_row >= 0 && new_row < 8) {
            // Check if landing tile is safe (not water without bridge, not void)
            var tile_safe = ai_is_tile_safe_for_move(_tiles, _bridges, new_col, new_row);
            if (!tile_safe) continue;
            
            var target = board[new_row][new_col];
            if (target == noone || target.piece_type != piece_type) {
                var is_capture = (target != noone);
                array_push(moves, {from_col: col, from_row: row, to_col: new_col, to_row: new_row, is_capture: is_capture, special: ""});
            }
        }
    }
    
    return moves;
}

/// @function ai_is_tile_safe_for_move(tiles, bridges, col, row)
/// @description Checks if a tile is safe to move to (not water without bridge, not void)
/// @returns {bool} True if safe to move to
function ai_is_tile_safe_for_move(_tiles, _bridges, _col, _row) {
    // If no tile data available, assume safe (standard chess board)
    if (_tiles == undefined) return true;
    if (_row < 0 || _row >= 8 || _col < 0 || _col >= 8) return false;
    
    var tile_type = _tiles[_row][_col];
    
    // Void tiles are never safe
    if (tile_type == -1) return false;
    
    // Water tiles need bridges
    if (tile_type == 1) {
        if (_bridges == undefined) return false;
        
        for (var b = 0; b < array_length(_bridges); b++) {
            if (_bridges[b].col == _col && _bridges[b].row == _row) {
                return true; // Has bridge
            }
        }
        return false; // Water without bridge
    }
    
    return true; // Normal tile
}

/// @function ai_get_sliding_moves_virtual(board, col, row, piece_type, directions)
/// @description Generates sliding piece moves with water/void tile awareness
function ai_get_sliding_moves_virtual(board, col, row, piece_type, directions) {
    var moves = [];
    
    // Get tile data from world state if available (for water/void blocking)
    var _tiles = undefined;
    var _bridges = undefined;
    if (variable_global_exists("ai_current_world_state") && global.ai_current_world_state != undefined) {
        _tiles = global.ai_current_world_state.tiles;
        _bridges = global.ai_current_world_state.objects.bridges;
    }
    
    for (var d = 0; d < array_length(directions); d++) {
        var dx = directions[d][0];
        var dy = directions[d][1];
        
        for (var dist = 1; dist <= 7; dist++) {
            var new_col = col + (dx * dist);
            var new_row = row + (dy * dist);
            
            if (new_col < 0 || new_col >= 8 || new_row < 0 || new_row >= 8) break;
            
            // Check for water/void tiles BEFORE checking for pieces
            // Water (tile_type 1) and void (tile_type -1) block sliding movement
            if (_tiles != undefined) {
                var tile_type = _tiles[new_row][new_col];
                
                if (tile_type == -1) {
                    // Void tile - completely blocks movement, can't even land on it
                    break;
                }
                
                if (tile_type == 1) {
                    // Water tile - check for bridge
                    var has_bridge = false;
                    if (_bridges != undefined) {
                        for (var b = 0; b < array_length(_bridges); b++) {
                            if (_bridges[b].col == new_col && _bridges[b].row == new_row) {
                                has_bridge = true;
                                break;
                            }
                        }
                    }
                    
                    if (!has_bridge) {
                        // Water without bridge - blocks sliding movement
                        break;
                    }
                    // If there's a bridge, continue normally
                }
            }
            
            var target = board[new_row][new_col];
            
            if (target == noone) {
                array_push(moves, {from_col: col, from_row: row, to_col: new_col, to_row: new_row, is_capture: false, special: ""});
            } else if (target.piece_type != piece_type) {
                array_push(moves, {from_col: col, from_row: row, to_col: new_col, to_row: new_row, is_capture: true, special: ""});
                break; // Can't move past capture
            } else {
                break; // Blocked by friendly piece
            }
        }
    }
    
    return moves;
}

/// @function ai_get_king_moves_virtual(board, col, row, piece_type, has_moved)
/// @description King move generation with water/void awareness
function ai_get_king_moves_virtual(board, col, row, piece_type, has_moved) {
    var moves = [];
    
    // Get tile data for water/void checking
    var _tiles = undefined;
    var _bridges = undefined;
    if (variable_global_exists("ai_current_world_state") && global.ai_current_world_state != undefined) {
        _tiles = global.ai_current_world_state.tiles;
        _bridges = global.ai_current_world_state.objects.bridges;
    }
    
    // Regular king moves (8 directions, 1 square)
    for (var dx = -1; dx <= 1; dx++) {
        for (var dy = -1; dy <= 1; dy++) {
            if (dx == 0 && dy == 0) continue;
            
            var new_col = col + dx;
            var new_row = row + dy;
            
            if (new_col >= 0 && new_col < 8 && new_row >= 0 && new_row < 8) {
                // Check if landing tile is safe
                var tile_safe = ai_is_tile_safe_for_move(_tiles, _bridges, new_col, new_row);
                if (!tile_safe) continue;
                
                var target = board[new_row][new_col];
                if (target == noone || target.piece_type != piece_type) {
                    var is_capture = (target != noone);
                    array_push(moves, {from_col: col, from_row: row, to_col: new_col, to_row: new_row, is_capture: is_capture, special: ""});
                }
            }
        }
    }
    
    // Castling (simplified - doesn't check for attacks through path in virtual)
    // Note: Full castling validation still happens in actual move execution
    if (!has_moved) {
        var castle_row = (piece_type == 0) ? 7 : 0;
        if (row == castle_row) {
            // Kingside castle - also check that path tiles are safe
            var ks_safe = ai_is_tile_safe_for_move(_tiles, _bridges, 5, row) && 
                          ai_is_tile_safe_for_move(_tiles, _bridges, 6, row);
            if (ks_safe && board[row][5] == noone && board[row][6] == noone) {
                var rook = board[row][7];
                if (rook != noone && rook.piece_id == "rook" && !rook.has_moved) {
                    array_push(moves, {from_col: col, from_row: row, to_col: 6, to_row: row, is_capture: false, special: "castle_k"});
                }
            }
            // Queenside castle
            var qs_safe = ai_is_tile_safe_for_move(_tiles, _bridges, 3, row) && 
                          ai_is_tile_safe_for_move(_tiles, _bridges, 2, row) &&
                          ai_is_tile_safe_for_move(_tiles, _bridges, 1, row);
            if (qs_safe && board[row][3] == noone && board[row][2] == noone && board[row][1] == noone) {
                var rook = board[row][0];
                if (rook != noone && rook.piece_id == "rook" && !rook.has_moved) {
                    array_push(moves, {from_col: col, from_row: row, to_col: 2, to_row: row, is_capture: false, special: "castle_q"});
                }
            }
        }
    }
    
    return moves;
}
