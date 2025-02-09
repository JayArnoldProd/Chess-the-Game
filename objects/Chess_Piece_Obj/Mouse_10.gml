// Chess_Piece_Obj Mouse Enter

if ((piece_type == 0 && Game_Manager.turn == 0) ||
    (piece_type == 1 && Game_Manager.turn == 1)) {
    Game_Manager.hovered_piece = self;
	audio_play_sound_on(audio_emitter,Piece_Hover_SFX, 0, false);
}

if Game_Manager.selected_piece != noone {
	Game_Manager.hovered_piece = self;
	audio_play_sound_on(audio_emitter,Piece_Hover_SFX, 0, false);
}