/// Enemy_Manager Step Event
/// Turn processing for enemy phase (turn == 2)

// Only process during enemy turn
if (!instance_exists(Game_Manager)) exit;

// Clean up dead enemies from the list
for (var i = array_length(enemy_list) - 1; i >= 0; i--) {
    if (!instance_exists(enemy_list[i])) {
        array_delete(enemy_list, i, 1);
    }
}

// State machine for enemy turn processing
switch (enemy_turn_state) {
    case "idle":
        if (Game_Manager.turn != 2) exit;
        
        // Safety: if no enemies, skip to AI turn immediately
        if (array_length(enemy_list) == 0) {
            show_debug_message("Enemy_Manager: No enemies, skipping to AI turn");
            Game_Manager.turn = 1;
            exit;
        }
        
        // Wait for any chess piece animations to finish
        var _any_moving = false;
        with (Chess_Piece_Obj) {
            if (is_moving) { _any_moving = true; break; }
        }
        if (_any_moving) exit;
        
        // Wait for any enemy knockback animations to finish
        with (Enemy_Obj) {
            if (is_moving) { _any_moving = true; break; }
        }
        if (_any_moving) exit;
        
        // Wait for conveyor belt animations to finish
        // Check both `animating` AND whether the belt hasn't caught up to the current turn yet
        // (handles case where Enemy_Manager runs before Factory_Belt_Obj in the same frame)
        with (Factory_Belt_Obj) {
            if (animating || last_turn != Game_Manager.turn) { _any_moving = true; break; }
        }
        if (_any_moving) exit;
        
        enemy_turn_state = "preparing";
        show_debug_message("Enemy_Manager: State -> PREPARING");
        break;
    
    case "preparing":
        // Build queue of living enemies
        enemies_to_process = [];
        for (var i = 0; i < array_length(enemy_list); i++) {
            if (instance_exists(enemy_list[i]) && !enemy_list[i].is_dead) {
                array_push(enemies_to_process, enemy_list[i]);
            }
        }
        current_enemy_index = 0;
        enemy_turn_active = true;
        
        if (array_length(enemies_to_process) == 0) {
            show_debug_message("Enemy_Manager: No living enemies to process");
            enemy_turn_state = "done";
        } else {
            show_debug_message("Enemy_Manager: Processing " + string(array_length(enemies_to_process)) + " enemies");
            enemy_turn_state = "processing";
        }
        break;
    
    case "processing":
        // Process the current enemy
        if (current_enemy_index >= array_length(enemies_to_process)) {
            enemy_turn_state = "done";
            break;
        }
        
        var _enemy = enemies_to_process[current_enemy_index];
        if (!instance_exists(_enemy) || _enemy.is_dead) {
            // Skip dead/destroyed enemies
            current_enemy_index++;
            break;
        }
        
        // Wait for this enemy to finish any knockback animation before giving it a turn
        if (_enemy.is_moving) break;
        
        // Find target and move
        enemy_process_turn(_enemy);
        enemy_turn_state = "waiting_animation";
        show_debug_message("Enemy_Manager: Enemy " + string(current_enemy_index) + " acting");
        break;
    
    case "waiting_animation":
        // Wait for current enemy to finish moving
        if (current_enemy_index >= array_length(enemies_to_process)) {
            enemy_turn_state = "done";
            break;
        }
        
        var _enemy = enemies_to_process[current_enemy_index];
        if (!instance_exists(_enemy) || !_enemy.is_moving) {
            // Enemy finished moving (or was destroyed), next enemy
            current_enemy_index++;
            if (current_enemy_index >= array_length(enemies_to_process)) {
                enemy_turn_state = "done";
            } else {
                enemy_turn_state = "processing";
            }
        }
        break;
    
    case "done":
        show_debug_message("Enemy_Manager: All enemies processed, switching to AI turn");
        enemy_turn_active = false;
        enemy_turn_state = "idle";
        Game_Manager.turn = 1;
        break;
}
