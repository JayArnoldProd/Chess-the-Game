// Game_Manager Draw GUI Event

var gui_w = display_get_gui_width();
var gui_h = display_get_gui_height();

// --- SETTINGS GEAR ICON (TOP-RIGHT CORNER) ---
// Always visible unless game over
if (!game_over) {
    var gear_size = 32; // Display size
    var gear_x = gui_w - 45;
    var gear_y = 45;
    
    // Store for click detection
    settings_icon_x = gear_x;
    settings_icon_y = gear_y;
    settings_icon_size = gear_size;
    
    // Hover effect
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    var hovering = point_distance(mx, my, gear_x, gear_y) < gear_size;
    
    // Draw gear icon (scaled down to fit)
    var sprite_w = sprite_get_width(spr_settings_icon);
    var scale = (sprite_w > 0) ? (gear_size / sprite_w) : 1;
    draw_set_alpha(hovering ? 1.0 : 0.7);
    draw_sprite_ext(spr_settings_icon, 0, gear_x, gear_y, scale, scale, 0, c_white, draw_get_alpha());
    draw_set_alpha(1);
}

// --- GAME OVER DISPLAY ---
if (game_over) {
    // Semi-transparent dark overlay
    draw_set_alpha(0.7);
    draw_set_color(c_black);
    draw_rectangle(0, 0, gui_w, gui_h, false);
    draw_set_alpha(1);
    
    // Game over text
    draw_set_font(-1);
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    
    // Draw shadow
    draw_set_color(c_black);
    draw_text_transformed(gui_w / 2 + 2, gui_h / 2 + 2, game_over_message, 3, 3, 0);
    
    // Draw main text
    draw_set_color(c_white);
    draw_text_transformed(gui_w / 2, gui_h / 2, game_over_message, 3, 3, 0);
    
    // Draw "Press R to restart" below
    draw_set_color(c_gray);
    draw_text_transformed(gui_w / 2, gui_h / 2 + 80, "Press R to restart", 1.5, 1.5, 0);
    
    // Reset draw state
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    
    game_over_timer++;
}

// --- CHECK WARNING TEXT ---
if (!game_over && turn == 0) {
    if (ai_is_king_in_check_simple(0)) {
        draw_set_font(-1);
        draw_set_halign(fa_center);
        draw_set_valign(fa_top);
        
        var pulse_alpha = 0.7 + 0.3 * sin(current_time / 150);
        draw_set_color(c_red);
        draw_set_alpha(pulse_alpha);
        draw_text_transformed(gui_w / 2, 20, "CHECK!", 2, 2, 0);
        draw_set_alpha(1);
        
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        draw_set_color(c_white);
    }
}

// --- AI THINKING INDICATOR (BELOW GEAR ICON) ---
if (!game_over && !settings_open && instance_exists(AI_Manager) && AI_Manager.ai_state == "searching") {
    draw_set_font(-1);
    draw_set_halign(fa_right);
    draw_set_valign(fa_top);
    
    // Animated dots
    var dots = "";
    for (var i = 0; i < AI_Manager.ai_thinking_dots; i++) dots += ".";
    
    // Small indicator
    draw_set_color(c_orange);
    draw_text(gui_w - 15, 75, "Thinking" + dots);
    
    var elapsed_ms = (get_timer() - AI_Manager.ai_search_start_time) / 1000;
    draw_set_color(c_ltgray);
    draw_text(gui_w - 15, 90, string(floor(elapsed_ms / 1000)) + "s");
    
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
}

// --- SETTINGS PANEL ---
if (settings_open) {
    // Initialize mute state if not exists
    if (!variable_global_exists("master_muted")) global.master_muted = false;
    
    // Panel dimensions (taller to fit volume control)
    var panel_w = 360;
    var panel_h = 480;
    var panel_x = (gui_w - panel_w) / 2;
    var panel_y = (gui_h - panel_h) / 2;
    
    // Store for click detection
    settings_panel_x = panel_x;
    settings_panel_y = panel_y;
    settings_panel_w = panel_w;
    settings_panel_h = panel_h;
    
    // Dim background
    draw_set_alpha(0.6);
    draw_set_color(c_black);
    draw_rectangle(0, 0, gui_w, gui_h, false);
    draw_set_alpha(1);
    
    // Panel background with border
    draw_set_color(#2a2a2a); // Dark gray
    draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, false);
    draw_set_color(#4a4a4a); // Lighter border
    draw_rectangle(panel_x, panel_y, panel_x + panel_w, panel_y + panel_h, true);
    draw_set_color(#5a5a5a);
    draw_rectangle(panel_x + 1, panel_y + 1, panel_x + panel_w - 1, panel_y + panel_h - 1, true);
    
    draw_set_font(-1);
    
    // === TITLE ===
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
    draw_text_transformed(panel_x + panel_w/2, panel_y + 12, "SETTINGS", 1.5, 1.5, 0);
    
    // Divider line
    draw_set_color(#4a4a4a);
    draw_line(panel_x + 15, panel_y + 45, panel_x + panel_w - 15, panel_y + 45);
    
    draw_set_halign(fa_left);
    var line_y = panel_y + 60;
    
    // === AI DIFFICULTY SECTION ===
    draw_set_color(#aaaaaa);
    draw_text(panel_x + 20, line_y, "AI Difficulty");
    line_y += 22;
    
    var btn_w = panel_w - 40;
    var btn_h = 26;
    var btn_spacing = 6;
    var btn_x = panel_x + 20;
    
    var diff_labels = ["Beginner", "Easy", "Medium", "Hard", "Grandmaster"];
    
    for (var i = 1; i <= 5; i++) {
        var btn_y = line_y + (i - 1) * (btn_h + btn_spacing);
        var is_selected = (global.ai_difficulty_level == i);
        
        // Store button positions for click detection
        variable_instance_set(id, "diff_btn_" + string(i) + "_x", btn_x);
        variable_instance_set(id, "diff_btn_" + string(i) + "_y", btn_y);
        variable_instance_set(id, "diff_btn_" + string(i) + "_w", btn_w);
        variable_instance_set(id, "diff_btn_" + string(i) + "_h", btn_h);
        
        // Button background
        draw_set_color(is_selected ? #e67e22 : #3a3a3a);
        draw_rectangle(btn_x, btn_y, btn_x + btn_w, btn_y + btn_h, false);
        
        // Button border
        draw_set_color(is_selected ? #f39c12 : #555555);
        draw_rectangle(btn_x, btn_y, btn_x + btn_w, btn_y + btn_h, true);
        
        // Button text
        draw_set_halign(fa_left);
        draw_set_valign(fa_middle);
        draw_set_color(c_white);
        draw_text(btn_x + 10, btn_y + btn_h/2, string(i) + " - " + diff_labels[i-1]);
    }
    
    line_y += 5 * (btn_h + btn_spacing) + 10;
    
    // Divider
    draw_set_color(#4a4a4a);
    draw_line(panel_x + 15, line_y, panel_x + panel_w - 15, line_y);
    line_y += 14;
    
    // === MASTER VOLUME SECTION ===
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(#aaaaaa);
    draw_text(panel_x + 20, line_y, "Master Volume");
    line_y += 22;
    
    // Mute toggle button
    var mute_btn_w = btn_w;
    var mute_btn_h = 32;
    var mute_btn_x = btn_x;
    var mute_btn_y = line_y;
    var is_muted = global.master_muted;
    
    // Store button position for click detection
    mute_btn_x_stored = mute_btn_x;
    mute_btn_y_stored = mute_btn_y;
    mute_btn_w_stored = mute_btn_w;
    mute_btn_h_stored = mute_btn_h;
    
    // Button background
    draw_set_color(is_muted ? #cc3333 : #33aa33);
    draw_rectangle(mute_btn_x, mute_btn_y, mute_btn_x + mute_btn_w, mute_btn_y + mute_btn_h, false);
    
    // Button border
    draw_set_color(is_muted ? #ff4444 : #44cc44);
    draw_rectangle(mute_btn_x, mute_btn_y, mute_btn_x + mute_btn_w, mute_btn_y + mute_btn_h, true);
    
    // Button text with icon
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    var mute_text = is_muted ? "🔇 MUTED - Click to Unmute" : "🔊 SOUND ON - Click to Mute";
    draw_text(mute_btn_x + mute_btn_w/2, mute_btn_y + mute_btn_h/2, mute_text);
    
    line_y += mute_btn_h + 14;
    
    // Divider
    draw_set_color(#4a4a4a);
    draw_line(panel_x + 15, line_y, panel_x + panel_w - 15, line_y);
    line_y += 14;
    
    // === CURRENT WORLD ===
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(#aaaaaa);
    draw_text(panel_x + 20, line_y, "Current World");
    line_y += 18;
    
    draw_set_color(#66ccff); // Light blue
    var world_name = room_get_name(room);
    world_name = string_replace_all(world_name, "_", " ");
    draw_text(panel_x + 30, line_y, world_name);
    line_y += 22;
    
    // Time limit display
    draw_set_color(#cccccc);
    var time_ms = (instance_exists(AI_Manager) ? AI_Manager.ai_time_limit : 0);
    var time_text = "Instant";
    if (time_ms > 0) {
        time_text = (time_ms >= 1000) ? (string(time_ms / 1000) + "s") : (string(time_ms) + "ms");
    }
    draw_text(panel_x + 20, line_y, "AI Think Time: " + time_text);
    
    // === CLOSE BUTTON ===
    var close_btn_w = 100;
    var close_btn_h = 30;
    var close_btn_x = panel_x + (panel_w - close_btn_w) / 2;
    var close_btn_y = panel_y + panel_h - 45;
    
    // Store for click detection
    close_btn_x_stored = close_btn_x;
    close_btn_y_stored = close_btn_y;
    close_btn_w_stored = close_btn_w;
    close_btn_h_stored = close_btn_h;
    
    // Check hover
    var mx = device_mouse_x_to_gui(0);
    var my = device_mouse_y_to_gui(0);
    var close_hover = (mx >= close_btn_x && mx <= close_btn_x + close_btn_w &&
                       my >= close_btn_y && my <= close_btn_y + close_btn_h);
    
    draw_set_color(close_hover ? #555555 : #3a3a3a);
    draw_rectangle(close_btn_x, close_btn_y, close_btn_x + close_btn_w, close_btn_y + close_btn_h, false);
    draw_set_color(#666666);
    draw_rectangle(close_btn_x, close_btn_y, close_btn_x + close_btn_w, close_btn_y + close_btn_h, true);
    
    draw_set_halign(fa_center);
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    draw_text(close_btn_x + close_btn_w/2, close_btn_y + close_btn_h/2, "CLOSE");
    
    // Reset
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);
    draw_set_color(c_white);
}
