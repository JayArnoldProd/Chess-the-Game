/// AI_Manager Draw_64 Event - MINIMAL VERSION

// Only draw debug if enabled
if (!variable_global_exists("ai_debug_visible")) global.ai_debug_visible = true;
if (!global.ai_debug_visible || !ai_enabled) exit;

// Set up text properties  
draw_set_font(-1);
draw_set_halign(fa_left);
draw_set_valign(fa_top);

var debug_x = 10;
var debug_y = 20;
var line_height = 14;
var current_line = 0;

// Debug Display Header
draw_set_color(c_yellow);
draw_text(debug_x, debug_y + (current_line * line_height), "=== AI DEBUG (MINIMAL) ===");
current_line++;

// AI Status
draw_set_color(c_white);
draw_text(debug_x, debug_y + (current_line * line_height), "AI Enabled: " + (ai_enabled ? "YES" : "NO"));
current_line++;

// Current Turn
var turn_color = Game_Manager.turn == 1 ? c_yellow : c_white;
draw_set_color(turn_color);
draw_text(debug_x, debug_y + (current_line * line_height), "Turn: " + (Game_Manager.turn == 1 ? "BLACK (AI)" : "WHITE (Player)"));
current_line++;

// Move delay countdown
if (variable_instance_exists(id, "ai_move_delay")) {
    draw_set_color(c_white);
    draw_text(debug_x, debug_y + (current_line * line_height), "AI Delay: " + string(ai_move_delay));
    current_line++;
}

// Difficulty
draw_set_color(c_white);
draw_text(debug_x, debug_y + (current_line * line_height), "Max Moves Considered: " + string(max_moves_to_consider));
current_line++;

// Moving Pieces Count
var moving_count = 0;
with (Chess_Piece_Obj) { 
    if (is_moving) moving_count++; 
}
var moving_color = moving_count > 0 ? c_yellow : c_white;
draw_set_color(moving_color);
draw_text(debug_x, debug_y + (current_line * line_height), "Moving Pieces: " + string(moving_count));
current_line++;

// Legal Moves Count (only if AI's turn)
if (Game_Manager.turn == 1) {
    try {
        var legal_moves = ai_get_legal_moves_fast(1);
        draw_set_color(c_white);
        draw_text(debug_x, debug_y + (current_line * line_height), "Legal Moves: " + string(array_length(legal_moves)));
        current_line++;
    } catch(e) {
        draw_set_color(c_red);
        draw_text(debug_x, debug_y + (current_line * line_height), "Legal Moves: ERROR");
        current_line++;
    }
}

// Skip a line
current_line++;

// Controls Section
draw_set_color(c_yellow);
draw_text(debug_x, debug_y + (current_line * line_height), "=== CONTROLS ===");
current_line++;

draw_set_color(c_ltgray);
draw_text(debug_x, debug_y + (current_line * line_height), "F1 - Toggle Debug");
current_line++;
draw_text(debug_x, debug_y + (current_line * line_height), "Ctrl+1-5 - Difficulty");
current_line++;

// Status messages
current_line++;
if (Game_Manager.turn == 1) {
    draw_set_color(c_yellow);
    draw_text(debug_x, debug_y + (current_line * line_height), "AI is thinking...");
    current_line++;
} else if (Game_Manager.turn == 0) {
    draw_set_color(c_lime);
    draw_text(debug_x, debug_y + (current_line * line_height), "Make your move!");
    current_line++;
}

// Reset drawing properties
draw_set_color(c_white);
draw_set_halign(fa_left);
draw_set_valign(fa_top);