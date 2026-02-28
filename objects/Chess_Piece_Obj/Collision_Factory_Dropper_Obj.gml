// Use tolerance check — belt movement can shift piece off exact position
if (abs(x - other.x) < Board_Manager.tile_size * 0.5 && abs(y - other.y) < Board_Manager.tile_size * 0.5) {
	audio_play_sound_on(audio_emitter, Trap_Door_SFX, 0, false);
	
	// End turn before destroying the piece
	if (piece_type == 0) {
		// Player piece died — switch to enemy turn if enemies exist, else AI turn
		if (instance_exists(Enemy_Manager) && array_length(Enemy_Manager.enemy_list) > 0) {
			Game_Manager.turn = 2;
		} else {
			Game_Manager.turn = 1;
		}
	} else if (piece_type == 1) {
		// AI piece died — switch to player turn
		Game_Manager.turn = 0;
	}
	
	// Deselect if this was the selected piece
	if (Game_Manager.selected_piece == id) {
		Game_Manager.selected_piece = noone;
	}
	
	instance_destroy();
}