if (x = other.x && y = other.y) {
	audio_play_sound_on(audio_emitter, Trap_Door_SFX, 0, false);
	instance_destroy();
}