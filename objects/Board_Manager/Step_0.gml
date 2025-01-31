with (Cursor_Obj) {
	color = c_white;
}

if room = Ruined_Overworld {
	white_textures = [1,2,3,4];
	black_textures = [0];
	white_color = make_colour_hsv(85, 172, 167); // green
	black_color = make_colour_hsv(24, 198, 82); // brown
	water_color = c_aqua;
	white_alpha = 1;
	black_alpha = 1;
	water_alpha = 1;
	var lay_id = layer_get_id("Background");
	var back_id = layer_background_get_id(lay_id);
	layer_background_change(back_id,Ruined_Overworld_Bg);
}

if room = Pirate_Seas {
	white_textures = [0];
	black_textures = [1,2,3,4];
	white_color = make_colour_hsv(42, 79, 255); // light tan
	black_color = make_colour_hsv(39, 255, 184); // dark yellow
	water_color = c_aqua;
	white_alpha = 1;
	black_alpha = 1;
	water_alpha = .5;
	var lay_id = layer_get_id("Background");
	var back_id = layer_background_get_id(lay_id);
	layer_background_change(back_id,Pirate_Seas_Bg);
}
