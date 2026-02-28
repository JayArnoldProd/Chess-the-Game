/// Enemy_Obj Destroy Event
if (audio_emitter != -1) {
    audio_emitter_free(audio_emitter);
}
show_debug_message("Enemy_Obj: Destroyed (type: " + enemy_type_id + ")");
