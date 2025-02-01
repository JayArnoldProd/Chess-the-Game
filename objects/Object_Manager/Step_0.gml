//Object_Manager Step
if instance_exists(Board_Manager) {
    tile_size = Board_Manager.tile_size;
}

if spawned_objects == false {
    // For each object type in object_locations
    for (var obj_type = 0; obj_type < array_length(object_locations); obj_type++) {
        var possible_layouts = object_locations[obj_type];
        
        // For each set of layouts for this object type
        for (var layout_set = 0; layout_set < array_length(possible_layouts); layout_set++) {
            var layouts = possible_layouts[layout_set];
            
            // Randomly pick one layout from this set
            var chosen_layout = layouts[irandom(array_length(layouts) - 1)];
            
            // Go through each position in the chosen layout
            for (var i = 0; i < array_length(chosen_layout); i++) {
                // Calculate x and y positions
                var grid_x = i mod 8;
                var grid_y = i div 8;
                
                // Check if this position should have an object
                var object_id = chosen_layout[i];
                if (object_id > 0) {
                    // Find the corresponding object from definitions
                    for (var def = 0; def < array_length(object_definitions); def++) {
                        if (object_definitions[def][1] == object_id) {
                            var object_to_spawn = object_definitions[def][0];
                            // Calculate actual position and create object, adding tile_size to x position
                            var spawn_x = topleft_x + (grid_x * tile_size);
                            var spawn_y = topleft_y + (grid_y * tile_size);
                            instance_create_depth(spawn_x, spawn_y, -1, object_to_spawn);
                            break;
                        }
                    }
                }
            }
        }
    }
    
    spawned_objects = true;
}