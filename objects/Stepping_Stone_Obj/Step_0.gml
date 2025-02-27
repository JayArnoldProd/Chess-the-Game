// -----------------------------
// Stepping_Stone_Obj Step Event
// -----------------------------
if (is_moving) {
    move_progress += 1 / move_duration;
    if (move_progress >= 1) {
        move_progress = 1;
        is_moving = false;
        x = move_target_x;
        y = move_target_y;
    } else {
        var t = easeInOutQuad(move_progress);
        x = lerp(move_start_x, move_target_x, t);
        y = lerp(move_start_y, move_target_y, t);
    }
}