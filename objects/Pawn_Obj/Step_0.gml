// -------------------------
// Pawn_Obj Step Event
// -------------------------
switch (piece_type) {
    case 0: // White pawn
        // Promote if reached the top row.
        if (y == Top_Row.y) {
            var temp = piece_type;
            instance_change(Queen_Obj, 1);
            piece_type = temp;
        }
        
        // Clear any previous moves.
        valid_moves = [];
        var _ts = Board_Manager.tile_size;
        
        // Check for enemy using grid position (reliable even after belt movement)
        // instance_position can miss due to spriteId=null, so also check grid coords
        var _fwd1_enemy = false;
        var _fwd2_enemy = false;
        var _diagL_enemy = false;
        var _diagR_enemy = false;
        var _fwd1_col = round((x - Object_Manager.topleft_x) / _ts);
        var _fwd1_row = round((y - Object_Manager.topleft_y) / _ts) - 1;
        var _fwd2_row = _fwd1_row - 1;
        
        with (Enemy_Obj) {
            if (is_dead) continue;
            if (grid_col == _fwd1_col && grid_row == _fwd1_row) _fwd1_enemy = true;
            if (grid_col == _fwd1_col && grid_row == _fwd2_row) _fwd2_enemy = true;
            if (grid_col == _fwd1_col - 1 && grid_row == _fwd1_row) _diagL_enemy = true;
            if (grid_col == _fwd1_col + 1 && grid_row == _fwd1_row) _diagR_enemy = true;
        }
        
        // Forward moves: one square if empty (no chess piece AND no enemy).
        if (instance_position(x, y - _ts, Chess_Piece_Obj) == noone && !_fwd1_enemy) {
            array_push(valid_moves, [0, -1]);
            
            // Two-square move: only if pawn hasn't moved and both squares are empty.
            if (has_moved == false) {
                if (instance_position(x, y - 2 * _ts, Chess_Piece_Obj) == noone && !_fwd2_enemy) {
                    array_push(valid_moves, [0, -2]);
                }
            }
        }
        
        // Diagonal captures (chess pieces OR enemies).
        var diagLeft = instance_position(x - _ts, y - _ts, Chess_Piece_Obj);
        if (diagLeft != noone && diagLeft.piece_type != 0) {
            array_push(valid_moves, [-1, -1]);
        } else if (_diagL_enemy) {
            array_push(valid_moves, [-1, -1]);
        }
        var diagRight = instance_position(x + _ts, y - _ts, Chess_Piece_Obj);
        if (diagRight != noone && diagRight.piece_type != 0) {
            array_push(valid_moves, [1, -1]);
        } else if (_diagR_enemy) {
            array_push(valid_moves, [1, -1]);
        }
        
        // En passant for White:
        if (Game_Manager.en_passant_target_x != -1) {
            // The target must be exactly one tile away horizontally and one tile above.
            if (abs(x - Game_Manager.en_passant_target_x) == Board_Manager.tile_size &&
                (y - Game_Manager.en_passant_target_y) == Board_Manager.tile_size) {
                var dx = (Game_Manager.en_passant_target_x - x) / Board_Manager.tile_size; // ±1
                var dy = (Game_Manager.en_passant_target_y - y) / Board_Manager.tile_size; // should be -1
                array_push(valid_moves, [dx, dy, "en_passant"]);
            }
        }
        break;
        
    case 1: // Black pawn
        // Promote if reached the bottom row.
        if (y == Bottom_Row.y) {
            var temp = piece_type;
            instance_change(Queen_Obj, 1);
            piece_type = temp;
        }
        
        valid_moves = [];
        var _ts = Board_Manager.tile_size;
        
        // Check for enemy using grid position (reliable even after belt movement)
        var _fwd1_enemy_b = false;
        var _fwd2_enemy_b = false;
        var _diagL_enemy_b = false;
        var _diagR_enemy_b = false;
        var _my_col_b = round((x - Object_Manager.topleft_x) / _ts);
        var _my_row_b = round((y - Object_Manager.topleft_y) / _ts);
        var _fwd1_row_b = _my_row_b + 1;
        var _fwd2_row_b = _my_row_b + 2;
        
        with (Enemy_Obj) {
            if (is_dead) continue;
            if (grid_col == _my_col_b && grid_row == _fwd1_row_b) _fwd1_enemy_b = true;
            if (grid_col == _my_col_b && grid_row == _fwd2_row_b) _fwd2_enemy_b = true;
            if (grid_col == _my_col_b - 1 && grid_row == _fwd1_row_b) _diagL_enemy_b = true;
            if (grid_col == _my_col_b + 1 && grid_row == _fwd1_row_b) _diagR_enemy_b = true;
        }
        
        // Forward moves for black (downward).
        if (instance_position(x, y + _ts, Chess_Piece_Obj) == noone && !_fwd1_enemy_b) {
            array_push(valid_moves, [0, 1]);
            if (has_moved == false) {
                if (instance_position(x, y + 2 * _ts, Chess_Piece_Obj) == noone && !_fwd2_enemy_b) {
                    array_push(valid_moves, [0, 2]);
                }
            }
        }
        
        // Diagonal captures (chess pieces OR enemies).
        var diagLeft_b = instance_position(x - _ts, y + _ts, Chess_Piece_Obj);
        if (diagLeft_b != noone && diagLeft_b.piece_type != 1) {
            array_push(valid_moves, [-1, 1]);
        } else if (_diagL_enemy_b) {
            array_push(valid_moves, [-1, 1]);
        }
        var diagRight_b = instance_position(x + _ts, y + _ts, Chess_Piece_Obj);
        if (diagRight_b != noone && diagRight_b.piece_type != 1) {
            array_push(valid_moves, [1, 1]);
        } else if (_diagR_enemy_b) {
            array_push(valid_moves, [1, 1]);
        }
        
        // En passant for Black:
        if (Game_Manager.en_passant_target_x != -1) {
            // For black, the target must be one tile away horizontally and one tile below.
            if (abs(x - Game_Manager.en_passant_target_x) == Board_Manager.tile_size &&
                (Game_Manager.en_passant_target_y - y) == Board_Manager.tile_size) {
                var dx = (Game_Manager.en_passant_target_x - x) / Board_Manager.tile_size; // ±1
                var dy = (Game_Manager.en_passant_target_y - y) / Board_Manager.tile_size; // should be 1
                array_push(valid_moves, [dx, dy, "en_passant"]);
            }
        }
        break;
}
event_inherited();