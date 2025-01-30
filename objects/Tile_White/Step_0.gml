event_inherited();

//Tile_White Step Event
if (tile_type = 0) { // only for normal tiles
	if !((image_index>=Board_Manager.white_textures[0]) and (image_index<=Board_Manager.white_textures[array_length(Board_Manager.white_textures)-1])) {
	    // Set random texture and rotation only once
	    image_index = Board_Manager.white_textures[round(random(array_length(Board_Manager.white_textures)-1))];
	    image_angle_ = round(random_range(0,3)) * 90;
	}
}

// Update color based on tile_type
if (instance_exists(Board_Manager)) {
    switch (tile_type) {
        case 0: //normal
            color = Board_Manager.white_color;
            break;
        case 1: //water
            color = Board_Manager.water_color;
            break;
    }
}
