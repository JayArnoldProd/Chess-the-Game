//Game_Manager Create
white_color = make_color_hsv(0,0,255);
black_color = make_color_hsv(0,0,40);

selected_piece = noone;
hovered_piece = noone;

//save army position and delete army manager
army_x = Player_Army_Manager.x;
army_y = Player_Army_Manager.y;
instance_destroy(Player_Army_Manager);

//foreground
if (!instance_exists(Foreground_Obj)) {
	instance_create_depth(x,y,-10,Foreground_Obj);
}

if (!instance_exists(Board_Manager)) {
	instance_create_depth(x,y,0,Board_Manager);
	Board_Manager.white_color = white_color;
	Board_Manager.black_color = black_color;
}

//recreate army manager
instance_create_depth(army_x,army_y,0,Player_Army_Manager);