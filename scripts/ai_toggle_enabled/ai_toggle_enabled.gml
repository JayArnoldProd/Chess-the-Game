/// @function ai_toggle_enabled()
/// @description Toggles AI on/off
function ai_toggle_enabled() {
    if (!instance_exists(AI_Manager)) return;
    
    AI_Manager.ai_enabled = !AI_Manager.ai_enabled;
    show_debug_message("AI enabled: " + string(AI_Manager.ai_enabled));
}
