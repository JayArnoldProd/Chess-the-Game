// Game_Manager KeyPress F2 - Toggle AI Debug Display
if (variable_global_exists("ai_debug_visible")) {
    global.ai_debug_visible = !global.ai_debug_visible;
    show_debug_message("AI debug display: " + (global.ai_debug_visible ? "ON" : "OFF"));
} else {
    global.ai_debug_visible = true;
}
