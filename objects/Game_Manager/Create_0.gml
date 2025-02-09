//Game_Manager Create
moveCancelled = false;

white_color = make_color_hsv(0,0,255);
black_color = make_color_hsv(0,0,40);

selected_piece = noone;
hovered_piece = noone;

// Initialize the turn variable (0 = player's turn, 1 = enemy's turn)
turn = 0;

//save army position and delete army manager
army_x = Player_Army_Manager.x;
army_y = Player_Army_Manager.y;
instance_destroy(Player_Army_Manager);

//foreground
if (!instance_exists(Foreground_Obj)) {
	instance_create_depth(x,y,-10,Foreground_Obj);
}

//background
if (room = Twisted_Carnival) {
	if (!instance_exists(Background_Obj)) {
		instance_create_depth(x,y,-10,Background_Obj);
	}
}

if (!instance_exists(Board_Manager)) {
	instance_create_depth(x,y,0,Board_Manager);
	Board_Manager.white_color = white_color;
	Board_Manager.black_color = black_color;
}

if (!instance_exists(Object_Manager)) {
	instance_create_depth(x,y,0,Object_Manager);
}

if (!instance_exists(Audio_Manager)) {
	instance_create_depth(x,y,0,Audio_Manager);
}

//recreate army manager
instance_create_depth(army_x,army_y,0,Player_Army_Manager);