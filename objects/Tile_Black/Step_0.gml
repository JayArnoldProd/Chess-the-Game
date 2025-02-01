//Tile_Black Step Event
event_inherited();

if (set_appearance == false && instance_exists(Board_Manager) && instance_exists(Object_Manager)) {
    var tile_size = Board_Manager.tile_size;
    grid_x = (x - Object_Manager.topleft_x) div tile_size;
    grid_y = 7 - ((y - Object_Manager.topleft_y) div tile_size);
    
    var override_found = false;
    
    // First pass: check only specific tile overrides
    for (var i = 0; i < array_length(Board_Manager.special_tile_textures); i++) {
        var override = Board_Manager.special_tile_textures[i];
        
        // Only check specific tile overrides (those that aren't "row" or "column")
        if (override[0] != "row" && override[0] != "column") {
            var col = ord(string_char_at(override[0], 1)) - ord("A");
            var row = real(string_delete(override[0], 1, 1)) - 1;
            if (grid_x == col && grid_y == row) {
                override_found = true;
                var override_hue = color_get_hue(override[2]);
                var override_sat = color_get_saturation(override[2]);
                var board_val = color_get_value(Board_Manager.black_color);
                color = make_colour_hsv(override_hue, override_sat, board_val);
                image_alpha = override[3];
                image_index = override[4];
                if (override[5]) {
                    image_angle_ = round(random_range(0,3)) * 90;
                } else {
                    image_angle_ = 0;
                }
                break;
            }
        }
    }
    
    // Second pass: check row/column overrides only if no specific tile override was found
    if (!override_found) {
        for (var i = 0; i < array_length(Board_Manager.special_tile_textures); i++) {
            var override = Board_Manager.special_tile_textures[i];
            var match = false;
            
            if (override[0] == "column" || override[0] == "row") {
                switch(override[0]) {
                    case "column":
                        match = (grid_x == override[1] - 1);
                        break;
                    case "row":
                        match = (grid_y == override[1] - 1);
                        break;
                }
                
                if (match) {
                    override_found = true;
                    var override_hue = color_get_hue(override[2]);
                    var override_sat = color_get_saturation(override[2]);
                    var board_val = color_get_value(Board_Manager.black_color);
                    color = make_colour_hsv(override_hue, override_sat, board_val);
                    image_alpha = override[3];
                    image_index = override[4];
                    if (override[5]) {
                        image_angle_ = round(random_range(0,3)) * 90;
                    } else {
                        image_angle_ = 0;
                    }
                    break;
                }
            }
        }
    }
    
    
    // If no overrides found, use default settings
	if (!override_found) {
		// Handle texture randomization only for normal tiles
		if (tile_type == 0) {
			if !((image_index>=Board_Manager.black_textures[0]) && (image_index<=Board_Manager.black_textures[array_length(Board_Manager.black_textures)-1])) {
				image_index = Board_Manager.black_textures[round(random(array_length(Board_Manager.black_textures)-1))];
				image_angle_ = round(random_range(0,3)) * 90;
			}
		}
    
		// Handle colors for all tile types
		switch (tile_type) {
			case 0: //normal
				color = Board_Manager.black_color;
				image_alpha = Board_Manager.black_alpha;
				break;
			case 1: //water
                var water_hue = color_get_hue(Board_Manager.water_color);
                var water_sat = color_get_saturation(Board_Manager.water_color);
                var black_val = color_get_value(Board_Manager.black_color);
                color = make_colour_hsv(water_hue, water_sat, black_val);
                image_alpha = Board_Manager.water_alpha;
                break;
		}
	}
    
    set_appearance = true;
}
