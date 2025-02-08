//Background_Obj Create
image_angle = 0;
depth = 50;
x = room_width/2;
y = room_height/2;

image_xscale=1.5;
image_yscale=1.5;

rotate_speed = .1;

var lay_id = layer_get_id("Background");
var back_id = layer_background_get_id(lay_id);
sprite_index = layer_background_get_sprite(back_id);