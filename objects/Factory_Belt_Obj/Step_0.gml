// Factory_Belt_Obj Step Event (Turn-Based Update)

// Check if the turn has changed:
if (Game_Manager.turn != last_turn) {
    // Store the old position for delta calculation:
    var old_pos = position;
    
    // Update position by 1 unit depending on direction:
    if (!right_direction) {
        position += speed_;
    } else {
        position -= speed_;
    }
    // Wrap position between 0 and 6:
    position = (position + 6) mod 6;
    
    // Compute the change (in tile-units) and then convert to pixels:
    var raw_delta = position - old_pos;
    // Adjust for wrapping if needed:
    if (raw_delta > 3) {
        raw_delta -= 6;
    } else if (raw_delta < -3) {
        raw_delta += 6;
    }
    var pixel_delta = raw_delta * 24;
    
    // Move any pieces on the belt by pixel_delta:
    var belt_left   = x;
    var belt_top    = y;
    var belt_right  = x + 144;  // 6 * 24
    var belt_bottom = y + 24;
    with (Chess_Piece_Obj) {
        var cx = x + sprite_width * 0.5;
        var cy = y + sprite_height * 0.5;
        if (cx >= belt_left && cx <= belt_right && cy >= belt_top && cy <= belt_bottom) {
            x += pixel_delta;
        }
    }
    
    // Update the last_turn variable.
    last_turn = Game_Manager.turn;
}