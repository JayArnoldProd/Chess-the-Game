// Audio_Manager Step Event

audio_group_set_gain(AG_MUSIC,.5,0);

// Set the listener position in the center of the screen with a fixed Z value
audio_listener_position(room_width / 2, room_height / 2, 0);

// Set listener orientation: Facing towards +Y (up in 2D space)
audio_listener_orientation(0, 1, 0, 0, 0, 1); // Forward vector (0,1,0), Up vector (0,0,1)

// Set default drop-off values for 2D audio
audio_falloff_set_model(audio_falloff_linear_distance);

music = noone;

switch (room) {
	case Ruined_Overworld:
		music = Ruined_Overworld_BattleTheme1;
	break;
	case Pirate_Seas:
		music = Pirate_Seas_BattleTheme1;
	break;
	case Volcanic_Wasteland:
		music = Volcanic_Wasteland_BattleTheme1;
	break;
	case Volcanic_Wasteland_Boss:
		music = Volcanic_Wasteland_BossTheme1;
	break;
	case Twisted_Carnival:
		music = Twisted_Carnival_BattleTheme1;
	break;
	case Void_Dimension:
		music = Void_Dimension_BattleTheme1;
	break;
}

//play music
if (!audio_is_playing(music)) {
	audio_stop_all();
	audio_play_sound(music,1,1);
}