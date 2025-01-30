//set size
if instance_exists(Board_Manager) {
	tile_size = Board_Manager.tile_size;
}

//set ocean tiles
if instance_exists(Ocean_Row) {
    var is_ocean = false;
    with (Ocean_Row) {
        if (other.y == y) {
            is_ocean = true;
            break;
        }
    }
    if (is_ocean) {
        tile_type = 1; // set to water
    }
}