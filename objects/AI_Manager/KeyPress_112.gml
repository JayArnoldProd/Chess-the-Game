if (!variable_global_exists("ai_debug_visible")) {
    global.ai_debug_visible = true;
} else {
    global.ai_debug_visible = !global.ai_debug_visible;
}
show_debug_message("Debug display: " + (global.ai_debug_visible ? "ON" : "OFF"));
