/// AI_Manager Draw_64 Event - COMPACT HORIZONTAL DEBUG DISPLAY

// Only draw if debug is enabled
if (!variable_global_exists("ai_debug_visible")) global.ai_debug_visible = false;
if (!global.ai_debug_visible || !ai_enabled) exit;

// Don't draw debug info if settings panel is open
if (instance_exists(Game_Manager) && Game_Manager.settings_open) exit;

// Update "Thinking..." animation timer
if (ai_state == "searching") {
    ai_thinking_timer++;
    if (ai_thinking_timer >= 20) {
        ai_thinking_timer = 0;
        ai_thinking_dots = (ai_thinking_dots + 1) mod 4;
    }
}

draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var line_h = 14;
var col1_x = 8;    // Left column
var col2_x = 330;  // Right column (beside col1, not below)
var start_y = 6;

// --- LEFT COLUMN: State + Turn + Search ---
var ly = start_y;

// State
var state_color = c_white;
switch (ai_state) {
    case "idle": state_color = c_lime; break;
    case "preparing": state_color = c_yellow; break;
    case "searching": state_color = c_orange; break;
    case "executing": state_color = c_aqua; break;
    case "waiting_turn_switch": state_color = c_fuchsia; break;
}
draw_set_color(state_color);
draw_text(col1_x, ly, "AI: " + string_upper(ai_state));
ly += line_h;

// Turn
var turn_text = (Game_Manager.turn == 1) ? "BLACK (AI)" : "WHITE (You)";
draw_set_color(Game_Manager.turn == 1 ? c_yellow : c_white);
draw_text(col1_x, ly, "Turn: " + turn_text);
ly += line_h;

// Difficulty + Time limit
draw_set_color(c_ltgray);
var diff_names = ["", "Beginner", "Easy", "Medium", "Hard", "GM"];
var diff_name = (global.ai_difficulty_level >= 1 && global.ai_difficulty_level <= 5) ? diff_names[global.ai_difficulty_level] : "?";
draw_text(col1_x, ly, "Diff: " + diff_name + " | Limit: " + string(ai_time_limit) + "ms");
ly += line_h;

// If searching: live progress
if (ai_state == "searching") {
    var elapsed_ms = (get_timer() - ai_search_start_time) / 1000;
    draw_set_color(c_orange);
    var dots = "";
    for (var i = 0; i < ai_thinking_dots; i++) dots += ".";
    draw_text(col1_x, ly, "Thinking" + dots + " D" + string(ai_search_current_depth) + " M" + string(ai_search_index + 1) + "/" + string(array_length(ai_search_moves)));
    ly += line_h;
    
    draw_set_color(c_white);
    draw_text(col1_x, ly, string(floor(elapsed_ms)) + "ms | " + string(global.ai_search_nodes) + " nodes");
    ly += line_h;
}

// --- RIGHT COLUMN: Last search + delay ---
var ry = start_y;

if (ai_last_search_time > 0 && ai_state != "searching") {
    draw_set_color(c_silver);
    draw_text(col2_x, ry, "Last: D" + string(ai_last_search_depth) + " S" + string(ai_last_search_score));
    ry += line_h;
    draw_text(col2_x, ry, string(ai_last_search_nodes) + "n " + string(ai_last_search_time) + "ms");
    ry += line_h;
}

// Move delay
if (variable_instance_exists(id, "ai_move_delay") && ai_move_delay > 0 && ai_state == "idle") {
    draw_set_color(c_ltgray);
    draw_text(col2_x, ry, "Delay: " + string(ai_move_delay));
    ry += line_h;
}

// Animating pieces
var moving_count = 0;
with (Chess_Piece_Obj) { if (is_moving) moving_count++; }
if (moving_count > 0) {
    draw_set_color(c_yellow);
    draw_text(col2_x, ry, "Anim: " + string(moving_count) + " pcs");
    ry += line_h;
}

// Reset
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);
