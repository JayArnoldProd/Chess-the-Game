// Game_Manager Key Press R
// Restart the room when game is over

if (game_over && game_over_timer >= 60) {
    // At least 1 second must pass before restart
    room_restart();
}
