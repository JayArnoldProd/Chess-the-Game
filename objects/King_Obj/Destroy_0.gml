// King_Obj Destroy Event

// Inherit parent's destroy event if any
event_inherited();

// When a king is destroyed, game over!
if (instance_exists(Game_Manager)) {
    Game_Manager.game_over = true;
    Game_Manager.game_over_timer = 0;
    
    // Determine winner based on which king was captured
    if (piece_type == 0) {
        // White (player) king captured - Black wins
        Game_Manager.game_over_message = "Checkmate!\nBlack Wins!";
    } else {
        // Black (AI) king captured - White wins  
        Game_Manager.game_over_message = "Checkmate!\nWhite Wins!";
    }
    
    show_debug_message("GAME OVER: " + Game_Manager.game_over_message);
}
