//Bridge_Row Create
bridge_count = 0;
bridge_width = 8;
tile_size = Board_Manager.tile_size;

// Randomize the seed when the room starts
randomize();

var max_attempts = 100;  // Prevent infinite loop
var attempts = 0;

// Keep trying until we have the desired number of bridges
while (bridge_count < bridge_amount && attempts < max_attempts) {
    // Get random position (accounting for bridge being 2 tiles wide already)
    var rand = irandom_range(0, bridge_width - 2);
    
    // Check if position and next position are free (since bridge is 2 tiles wide)
    var check_x = x + (rand * tile_size);
    if (!instance_position(check_x, y, Bridge_Obj) && 
        !instance_position(check_x + tile_size, y, Bridge_Obj)) {
        // Create single bridge instance (already 2 tiles wide)
        var bridge = instance_create_depth(check_x, y, -1, Bridge_Obj);
        with (bridge) {
            bridge_number = other.bridge_count;
        }
        bridge_count++;
    }
    attempts++;
}

// If we didn't get enough bridges, try again
if (bridge_count < bridge_amount) {
    // Destroy any existing bridges
    with (Bridge_Obj) instance_destroy();
    bridge_count = 0;
    event_perform(ev_create, 0);  // Run create event again
}