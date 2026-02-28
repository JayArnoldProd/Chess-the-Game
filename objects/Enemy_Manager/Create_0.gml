/// Enemy_Manager Create Event
show_debug_message("Enemy_Manager: Initializing...");

// Initialize enemy definitions
if (!variable_global_exists("enemy_definitions") || 
    !ds_exists(global.enemy_definitions, ds_type_map)) {
    enemy_definitions_init();
}

// Enemy tracking
enemy_list = [];

// Level configuration (overridden per-room by PRP-009)
level_enemy_min = 0;
level_enemy_max = 0;
level_enemy_types = [];

// Turn processing state (PRP-010)
enemies_to_process = [];
current_enemy_index = 0;
enemy_turn_active = false;
enemy_turn_state = "idle";

// Spawning state (PRP-009)
spawn_complete = false;
spawn_delay_timer = 0;

show_debug_message("Enemy_Manager: Ready (" + 
    string(ds_map_size(global.enemy_definitions)) + " enemy types loaded)");

// TEST: Auto-spawn placeholder enemies after board setup (all rooms)
alarm[0] = 60; // 1 second delay for board to initialize
