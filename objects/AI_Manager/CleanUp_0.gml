/// AI_Manager Cleanup Event - WITH STEPPING STONE CLEANUP
if (ds_exists(piece_values, ds_type_map)) {
    ds_map_destroy(piece_values);
}

// Clean up stepping stone references
ai_stepping_piece = noone;
ai_stepping_phase = 0;

show_debug_message("AI_Manager: Cleaned up");