/// AI_Manager Create Event - WITH STEPPING STONE SUPPORT
show_debug_message("AI_Manager: Starting AI with stepping stone support...");

// Basic AI settings
ai_enabled = true;
ai_move_delay = 30;

// Stepping stone variables
ai_stepping_phase = 0; // 0 = normal, 1 = phase1 pending, 2 = phase2 pending
ai_stepping_piece = noone;

// Simple piece values
piece_values = ds_map_create();
ds_map_add(piece_values, "pawn", 100);
ds_map_add(piece_values, "knight", 320);
ds_map_add(piece_values, "bishop", 330);
ds_map_add(piece_values, "rook", 500);
ds_map_add(piece_values, "queen", 900);
ds_map_add(piece_values, "king", 20000);

// Simple difficulty settings
search_depth = 1;
max_moves_to_consider = 8;

// Initialize global debug variable
global.ai_debug_visible = true;

show_debug_message("AI_Manager: Ready with animation and stepping stone support");
