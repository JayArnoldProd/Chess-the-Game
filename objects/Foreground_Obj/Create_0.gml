//Foreground_Obj Create
sprite_index = Empty_Foreground_Sprite;
image_alpha = 1;

// Layer 1 (slowest)
max_vspeed = 0.5;
max_hspeed = 0.5;
v_speed = random_range(-max_vspeed/2, max_vspeed/2);  // Start at half max speed
h_speed = random_range(-max_hspeed/2, max_hspeed/2);
x1 = 0;
y1 = 0;

// Layer 2 (medium)
max_vspeed2 = 0.75;
max_hspeed2 = 0.75;
v_speed2 = random_range(-max_vspeed2/2, max_vspeed2/2);
h_speed2 = random_range(-max_hspeed2/2, max_hspeed2/2);
x2 = 0;
y2 = 0;

// Layer 3 (fastest)
max_vspeed3 = 1.0;
max_hspeed3 = 1.0;
v_speed3 = random_range(-max_vspeed3/2, max_vspeed3/2);
h_speed3 = random_range(-max_hspeed3/2, max_hspeed3/2);
x3 = 0;
y3 = 0;