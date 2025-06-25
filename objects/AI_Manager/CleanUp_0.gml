// AI_Manager Cleanup Event

// Clean up transposition table
if (ds_exists(transposition_table, ds_type_map)) {
    ds_map_destroy(transposition_table);
}