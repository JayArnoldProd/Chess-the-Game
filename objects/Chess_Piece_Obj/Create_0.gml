// Chess_Piece_Obj Create
image_index = 0;
image_speed = 0;

can_move_through_pieces = false;
valid_moves = [[0,0]];
direction_moves = [[]];

has_moved = false;

piece_type = 0; // 0 = white, 1 = black, 2 = corrupted
piece_id = "pawn";

depth = -1;
health_ = 1;
original_depth = depth;
landing_sound_pending = false;

// Extra–move (stepping stone) state initialization
extra_move_pending = false;   // (alternative name: not used beyond activation)
stepping_chain = 0;           // 0 = no chain; 2 = extra move phase 1 pending; 1 = extra move phase 2 pending
stepping_stone_instance = noone;  // Will store the activated stepping stone’s instance id
stone_original_x = 0;         // Save original position so we can revert later
stone_original_y = 0;

stepping_stone_used = false;  // True after completing a stepping stone sequence this turn

pre_stepping_x = x;
pre_stepping_y = y;

last_x = x;
last_y = y;

original_turn_x = x;
original_turn_y = y;
original_has_moved = has_moved; 

// Animation
move_start_x = 0;
move_start_y = 0;
move_target_x = 0; 
move_target_y = 0;
move_progress = 0;
move_duration = 200;
is_moving = false;
move_animation_type = "linear";

pending_capture = noone;
pending_capture_check = false;
pending_turn_switch = undefined;
pending_en_passant = false;
pending_normal_move = false;

destroy_pending = false;
destroy_target_x = 0;
destroy_target_y = 0;
destroy_tile_type = 0;

landing_sound= Piece_Landing_SFX

// Create an audio emitter for this piece
audio_emitter = audio_emitter_create();

// Position the emitter at the piece's location
audio_emitter_position(audio_emitter, x, y, 0);

// Set default falloff settings for 2D spatial audio
audio_emitter_falloff(audio_emitter, 32, 400, 1); // Min distance, Max distance, Exponent
audio_emitter_velocity(audio_emitter, 0, 0, 0);   // No velocity changes needed
audio_emitter_gain(audio_emitter, 1);             // Full volume