/// Enemy_Obj Create Event
show_debug_message("Enemy_Obj: Creating instance...");

// Identity
enemy_type_id = "placeholder";
enemy_def = undefined;

// Combat
current_hp = 1;
max_hp = 1;
is_dead = false;

// Grid position
grid_col = 0;
grid_row = 0;

// Turn state (PRP-010)
enemy_state = "idle";
state_timer = 0;

// Targeting
target_piece = noone;
target_col = -1;
target_row = -1;
highlighted_tiles = [];

// Movement interpolation
is_moving = false;
move_start_x = 0;
move_start_y = 0;
move_target_x = 0;
move_target_y = 0;
move_progress = 0;
move_duration = 30;

// Knockback
knockback_pending = false;
knockback_dir_x = 0;
knockback_dir_y = 0;

// Hit flash
hit_flash_timer = 0;
hit_flash_duration = 12;  // ~0.2 seconds at 60fps

// Death animation
death_timer = 0;
death_duration = 60;
death_shake_intensity = 4;

// Visual — use Pawn_Sprite for collision mask, but we draw manually in Draw_0
depth = -1;  // Same layer as chess pieces — indicators (drawn by selected piece at depth -2) render on top
sprite_index = Pawn_Sprite;
image_index = 0;
image_speed = 0;
visible = true;  // Must be true for instance_position/instance_place to detect us
draw_hp_bar = true;
hp_bar_offset_y = -4;  // Above the flipped sprite

// Audio
audio_emitter = audio_emitter_create();
audio_emitter_position(audio_emitter, x, y, 0);
audio_emitter_falloff(audio_emitter, 32, 400, 1);

show_debug_message("Enemy_Obj: Instance created (type: " + enemy_type_id + ")");
