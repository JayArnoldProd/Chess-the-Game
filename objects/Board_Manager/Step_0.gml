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
	black_random_rotate = false;
	white_random_rotate = true;
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
	black_random_rotate = true;
	white_random_rotate = true;
	var lay_id = layer_get_id("Background");
	var back_id = layer_background_get_id(lay_id);
	layer_background_change(back_id,Pirate_Seas_Bg);
}

if room = Volcanic_Wasteland {
	white_textures = [5];
	black_textures = [0];
	white_color = make_colour_hsv(13, 255, 227); // orange/red
	black_color = make_colour_hsv(241, 100, 100); // maroon
	water_color = c_red;
	white_alpha = 1;
	black_alpha = 1;
	water_alpha = .5;
	black_random_rotate = true;
	white_random_rotate = true;
	var lay_id = layer_get_id("Background");
	var back_id = layer_background_get_id(lay_id);
	layer_background_change(back_id,Volcanic_Wasteland_Bg);
}

if room = Volcanic_Wasteland_Boss {
	white_textures = [10];
	black_textures = [9];
	white_color = make_colour_hsv(0, 0, 140); // light grey
	black_color = make_colour_hsv(0, 0, 130); // dark grey
	water_color = c_red;
	white_alpha = 1;
	black_alpha = 1;
	water_alpha = .5;
	black_random_rotate = true;
	white_random_rotate = false;
	var lay_id = layer_get_id("Background");
	var back_id = layer_background_get_id(lay_id);
	layer_background_change(back_id,Volcanic_Wasteland_Bg);

	 //row/column/specific tile, 
 //row/column number (0 for specific tile, 
 //blend color, 
 //alpha
 //sprite_index, 
 //random rotation?

	special_tile_textures = [
		["column", 4, c_red, 1, 13, false],
		["column", 5, c_red, 1, 13, false],
		["D1", 0, c_white, 1, 11, false],
		["E1", 0, c_white, 1, 12, false]
	]
}

if room = Twisted_Carnival {
	white_textures = [15,16,17,18];
	black_textures = [0];
	white_color = make_colour_hsv(85, 118, 88); // green
	black_color = make_colour_hsv(195, 173, 135); // purple
	water_color = c_green;
	white_alpha = 1;
	black_alpha = 1;
	water_alpha = .5;
	black_random_rotate = false;
	white_random_rotate = false;
	var lay_id = layer_get_id("Background");
	var back_id = layer_background_get_id(lay_id);
	layer_background_change(back_id,Twisted_Carnival_Bg);
}


if room = Void_Dimension {
	white_textures = [6,7,8];
	black_textures = [0];
	white_color = make_colour_hsv(195, 56, 121); // lavender
	black_color = c_black; // black
	water_color = c_black;
	white_alpha = 1;
	black_alpha = 0;
	water_alpha = .5;
	black_random_rotate = true;
	white_random_rotate = true;
	var lay_id = layer_get_id("Background");
	var back_id = layer_background_get_id(lay_id);
	layer_background_change(back_id,Void_Dimension_Bg);
	Foreground_Obj.sprite_index = Void_Dimension_Fg;
	Foreground_Obj.image_alpha = .75;
}

