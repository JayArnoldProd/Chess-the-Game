//Foreground_Obj Step
x1 += h_speed;
y1 += v_speed;

// Gradually change speeds
h_speed += random_range(-0.02*max_vspeed, 0.02*max_vspeed);
v_speed += random_range(-0.02*max_vspeed, 0.02*max_vspeed);

// Clamp speeds to max values
h_speed = clamp(h_speed, -max_hspeed, max_hspeed);
v_speed = clamp(v_speed, -max_vspeed, max_vspeed);

//loop layer
if (x1<0 or x1>room_width or y1<0 or y1>room_height) {
	if x1>room_width {
		x1-= room_width;
	}
	if x1<0 {
		x1+= room_width;
	}
	if y1>room_height {
		y1-= room_height;
	}
	if y1<0 {
		y1+= room_height;
	}
}

//layer 2

if (image_number > 0) {
	x2 += h_speed2;
	y2 += v_speed2;

	// Gradually change speeds
	h_speed2 += random_range(-0.02*max_vspeed2, 0.02*max_vspeed2);
	v_speed2 += random_range(-0.02*max_vspeed2, 0.02*max_vspeed3);

	// Clamp speeds to max values
	h_speed2 = clamp(h_speed2, -max_hspeed2, max_hspeed2);
	v_speed2 = clamp(v_speed2, -max_vspeed2, max_vspeed2);
	
	//loop layer
	if (x2<0 or x2>room_width or y2<0 or y2>room_height) {
		if x2>room_width {
			x2-= room_width;
		}
		if x2<0 {
			x2+= room_width;
		}
		if y2>room_height {
			y2-= room_height;
		}
		if y2<0 {
			y2+= room_height;
		}
	}
}

//layer 3

if (image_number > 1) {
	x3 += h_speed3;
	y3 += v_speed3;

	// Gradually change speeds
	h_speed3 += random_range(-0.02*max_vspeed3, 0.02*max_vspeed3);
	v_speed3 += random_range(-0.02*max_vspeed3, 0.02*max_vspeed3);

	// Clamp speeds to max values
	h_speed3 = clamp(h_speed3, -max_hspeed3, max_hspeed3);
	v_speed3 = clamp(v_speed3, -max_vspeed3, max_vspeed3);
	
	//loop layer
	if (x3<0 or x3>room_width or y3<0 or y3>room_height) {
		if x3>room_width {
			x3-= room_width;
		}
		if x3<0 {
			x3+= room_width;
		}
		if y3>room_height {
			y3-= room_height;
		}
		if y3<0 {
			y3+= room_height;
		}
	}
}




