/// Game_Manager KeyPress E — Debug enemy spawn
if (keyboard_check(vk_shift)) {
    var _col = irandom(7);
    var _row = irandom_range(5, 7);
    enemy_create("placeholder", _col, _row);
    show_debug_message("DEBUG: Spawned test enemy at (" + string(_col) + "," + string(_row) + ")");
}
