// Game_Manager Step Event

// --- ENEMY HOVER DETECTION (Enemy_Obj has no spriteId) ---
if (instance_exists(Object_Manager) && instance_exists(Board_Manager) && instance_exists(Enemy_Manager)) {
    var _mx = mouse_x;
    var _my = mouse_y;
    var _col = floor((_mx - Object_Manager.topleft_x) / Board_Manager.tile_size);
    var _row = floor((_my - Object_Manager.topleft_y) / Board_Manager.tile_size);
    var _found = noone;
    if (_col >= 0 && _col < 8 && _row >= 0 && _row < 8) {
        for (var e = 0; e < array_length(Enemy_Manager.enemy_list); e++) {
            var _en = Enemy_Manager.enemy_list[e];
            if (instance_exists(_en) && !_en.is_dead && _en.grid_col == _col && _en.grid_row == _row) { _found = _en; break; }
        }
    }
    hovered_enemy = _found;
}

// --- CHECKMATE DETECTION (player's turn only) ---
if (turn == 0 && !game_over) {
    if (ai_is_king_in_check_simple(0)) {
        // Player king is in check — see if ANY player piece has a legal move
        var _has_legal_move = false;
        
        with (Chess_Piece_Obj) {
            if (piece_type != 0) continue;  // Skip non-player pieces
            if (_has_legal_move) break;     // Already found one, done
            
            // Check each valid move to see if it escapes check
            for (var i = 0; i < array_length(valid_moves); i++) {
                var _mv = valid_moves[i];
                var _dx = _mv[0];
                var _dy = _mv[1];
                var _dest_x = x + _dx * Board_Manager.tile_size;
                var _dest_y = y + _dy * Board_Manager.tile_size;
                
                if (!move_leaves_king_in_check(id, _dest_x, _dest_y)) {
                    _has_legal_move = true;
                    break;
                }
            }
            
            // Also check castle moves for king
            if (!_has_legal_move && object_index == King_Obj && array_length(castle_moves) > 0) {
                for (var i = 0; i < array_length(castle_moves); i++) {
                    var _cm = castle_moves[i];
                    var _castle_x = x + _cm[0] * Board_Manager.tile_size;
                    if (!move_leaves_king_in_check(id, _castle_x, y)) {
                        _has_legal_move = true;
                        break;
                    }
                }
            }
        }
        
        if (!_has_legal_move) {
            // CHECKMATE!
            game_over = true;
            game_over_message = "CHECKMATE!";
            game_over_timer = 0;
            show_debug_message("CHECKMATE detected — player has no legal moves!");
        }
    }
}

// Handle settings interaction via polling
// (Mouse_6 was Middle Button Pressed which never fires; use Step + mouse_check instead)

if (mouse_check_button_pressed(mb_left)) {
    if (game_over) exit;
    
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    var gui_w = display_get_gui_width();
    
    // === GEAR ICON CLICK (TOGGLE SETTINGS) ===
    var gear_size = 32;
    var gear_x = gui_w - 45;
    var gear_y = 45;
    
    var gear_dist = point_distance(mx, my, gear_x, gear_y);
    if (gear_dist < gear_size) {
        settings_open = !settings_open;
        audio_play_sound(Piece_Selection_SFX, 1, false);
        show_debug_message("Settings " + (settings_open ? "opened" : "closed"));
        exit;
    }
    
    // === SETTINGS PANEL INTERACTION ===
    if (!settings_open) exit;
    
    // Check if click is inside panel
    var in_panel = (mx >= settings_panel_x && mx <= settings_panel_x + settings_panel_w &&
                    my >= settings_panel_y && my <= settings_panel_y + settings_panel_h);
    
    if (!in_panel) {
        settings_open = false;
        show_debug_message("Settings closed (clicked outside)");
        exit;
    }
    
    // === CLOSE BUTTON CLICK ===
    if (variable_instance_exists(id, "close_btn_x_stored")) {
        if (mx >= close_btn_x_stored && mx <= close_btn_x_stored + close_btn_w_stored &&
            my >= close_btn_y_stored && my <= close_btn_y_stored + close_btn_h_stored) {
            settings_open = false;
            audio_play_sound(Piece_Selection_SFX, 1, false);
            show_debug_message("Settings closed via Close button");
            exit;
        }
    }
    
    // === MUTE TOGGLE BUTTON CLICK ===
    if (variable_instance_exists(id, "mute_btn_x_stored")) {
        if (mx >= mute_btn_x_stored && mx <= mute_btn_x_stored + mute_btn_w_stored &&
            my >= mute_btn_y_stored && my <= mute_btn_y_stored + mute_btn_h_stored) {
            if (!variable_global_exists("master_muted")) global.master_muted = false;
            global.master_muted = !global.master_muted;
            
            if (global.master_muted) {
                audio_master_gain(0);
                show_debug_message("Audio MUTED");
            } else {
                audio_master_gain(1);
                show_debug_message("Audio UNMUTED");
            }
            
            if (!global.master_muted) {
                audio_play_sound(Piece_Selection_SFX, 1, false);
            }
            exit;
        }
    }
    
    // === DIFFICULTY BUTTON CLICKS ===
    for (var i = 1; i <= 5; i++) {
        var btn_x = variable_instance_get(id, "diff_btn_" + string(i) + "_x");
        var btn_y = variable_instance_get(id, "diff_btn_" + string(i) + "_y");
        var btn_w = variable_instance_get(id, "diff_btn_" + string(i) + "_w");
        var btn_h = variable_instance_get(id, "diff_btn_" + string(i) + "_h");
        
        if (btn_x != undefined && mx >= btn_x && mx <= btn_x + btn_w && my >= btn_y && my <= btn_y + btn_h) {
            ai_set_difficulty_simple(i);
            audio_play_sound(Piece_Selection_SFX, 1, false);
            show_debug_message("Difficulty changed to: " + string(i));
            exit;
        }
    }
}
