// Tile_Obj Create
white = false;
valid_move = false;
image_speed = 0;
image_index = 0;
image_alpha = 1;
image_angle_ = 0;

depth = 5;

tile_size = 24;

//tile tile_types
// -1 = void, 0 = normal, 1 = water,
tile_type = 0;

//randomize images
randomized = false;

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