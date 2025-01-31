//Board_Manager Create
world_id = 0;
tile_size = 24;
white_textures = [0];
black_textures = [0];

white_color = make_color_hsv(0,0,255);
black_color = make_color_hsv(0,0,40);
water_color = c_aqua;
white_alpha = 1;
black_alpha = 1;
water_alpha = 1;

if (!instance_exists(Cursor_Obj)) {
	instance_create_depth(mouse_x,mouse_y,-2,Cursor_Obj);
}