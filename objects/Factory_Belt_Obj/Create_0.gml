// Factory_Belt_Obj Create Event
position = 0;           
old_position = position;
target_position = position;
belt_anim_progress = 0;
animating = false;
belt_speed = 0.02;
Factory_Belt_Sprite = sprite_index;
last_effective_offset = position * Board_Manager.tile_size;
last_unwrapped_offset = position * Board_Manager.tile_size;
last_turn = Game_Manager.turn;

audio_emitter = audio_emitter_create();

// Position the emitter at the piece's location
audio_emitter_position(audio_emitter, x + sprite_width/2, y + sprite_height/2, 0);

// Set default falloff settings for 2D spatial audio
audio_emitter_falloff(audio_emitter, 32, 400, 1); // Min distance, Max distance, Exponent
audio_emitter_velocity(audio_emitter, 0, 0, 0);   // No velocity changes needed
audio_emitter_gain(audio_emitter, .5);             // Full volume