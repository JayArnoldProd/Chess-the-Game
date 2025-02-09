white = false;
color = make_colour_hsv(0, 0, 50);
sprite_index = Tile_Sprite_White;

image_speed = 0;
image_index = 0;
image_alpha = 1;
image_angle_ = 0;

depth = 5;

//tile tile_types
// 0 = normal, 1 = water
tile_type = 0;

valid_move = false;

set_appearance = false;

grid_x = 0;
grid_y = 0;

// Create an audio emitter for this piece
audio_emitter = audio_emitter_create();

// Position the emitter at the piece's location
audio_emitter_position(audio_emitter, x, y, 0);

// Set default falloff settings for 2D spatial audio
audio_emitter_falloff(audio_emitter, 32, 400, 1); // Min distance, Max distance, Exponent
audio_emitter_velocity(audio_emitter, 0, 0, 0);   // No velocity changes needed
audio_emitter_gain(audio_emitter, 1);             // Full volume