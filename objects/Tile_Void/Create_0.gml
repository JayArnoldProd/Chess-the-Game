white = true;
color = make_colour_hsv(0, 0, 255);
sprite_index = Tile_Sprite_Void;

image_speed = 0;
image_index = 0;
image_alpha = 0;
image_angle_ = 0;

depth = 5;

//tile tile_types
// -1 = void, 0 = normal, 1 = water
tile_type = -1;

valid_move = false;

// Create an audio emitter for this piece
audio_emitter = audio_emitter_create();

// Position the emitter at the piece's location
audio_emitter_position(audio_emitter, x, y, 0);

// Set default falloff settings for 2D spatial audio
audio_emitter_falloff(audio_emitter, 32, 400, 1); // Min distance, Max distance, Exponent
audio_emitter_velocity(audio_emitter, 0, 0, 0);   // No velocity changes needed
audio_emitter_gain(audio_emitter, 1);             // Full volume