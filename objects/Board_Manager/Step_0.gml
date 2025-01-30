with (Cursor_Obj) {
	color = c_white;
}

if room = Ruined_Overworld {
	white_textures = [1,2,3,4];
	black_textures = [0];
	white_color = make_colour_hsv(85, 172, 167); // green
	black_color = make_colour_hsv(24, 198, 82); // brown
	water_color = c_aqua;
}

if room = Pirate_Seas {
	white_textures = [0];
	black_textures = [1,2,3,4];
	white_color = make_colour_hsv(42, 79, 255); // light tan
	black_color = make_colour_hsv(39, 255, 184); // dark yellow
	water_color = c_aqua;
}