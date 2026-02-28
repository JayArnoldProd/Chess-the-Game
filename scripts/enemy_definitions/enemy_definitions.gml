/// @function enemy_definitions_init()
/// @description Initialize all enemy type definitions
function enemy_definitions_init() {
    global.enemy_definitions = ds_map_create();
    
    // === PLACEHOLDER ENEMY ===
    var _placeholder = {
        enemy_id: "placeholder",
        display_name: "Placeholder Enemy",
        
        // Combat
        max_hp: 2,
        
        // Hitbox
        hitbox_width: 1,
        hitbox_height: 1,
        
        // Movement (king-style: 1 tile, 8 directions)
        movement_type: "king",
        movement_speed: 30,
        
        // Attack
        attack_type: "melee",
        attack_site_width: 3,
        attack_site_height: 3,
        attack_size_width: 1,
        attack_size_height: 1,
        attack_warning_turns: 1,
        
        // Spawning
        spawn_rules: {
            default_ranks: [0, 1, 2],
            lane_lock: -1,
            exact_tile: noone,
            avoid_occupied: true
        },
        
        // Visuals (upside-down tinted pawn as placeholder)
        sprite_idle: Pawn_Sprite,
        sprite_attack: Pawn_Sprite,
        sprite_hurt: Pawn_Sprite,
        sprite_death: Pawn_Sprite,
        tint_color: make_color_rgb(255, 140, 0),  // Orange tint
        
        // Audio
        sound_attack: noone,
        sound_hurt: noone,
        sound_death: noone
    };
    
    ds_map_add(global.enemy_definitions, "placeholder", _placeholder);
    
    show_debug_message("Enemy definitions initialized: " + string(ds_map_size(global.enemy_definitions)) + " types");
}

/// @function enemy_definitions_cleanup()
/// @description Clean up enemy definitions
function enemy_definitions_cleanup() {
    if (ds_exists(global.enemy_definitions, ds_type_map)) {
        ds_map_destroy(global.enemy_definitions);
    }
}
