//Object_Manager Create
var closest_x = infinity;
var closest_y = infinity;

with (Tile_Obj) {
    if (x < closest_x) closest_x = x;
    if (y < closest_y) closest_y = y;
}

topleft_x = closest_x;
topleft_y = closest_y;

tile_size = 24;

object_definitions = [
	[Stepping_Stone_Obj, 1], //defines the stepping stone as a 1
	//add additional object definitions here
]

if room = Ruined_Overworld {
object_locations = [
	[
		[ // this array just spawns stones in various combinations
			[ 0, 0, 0, 0, 0, 0, 0, 0, //1
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 1, 0, 0, 0, 0, 1, 0,
			  0, 0, 0, 0, 1, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0]
			,
			[ 0, 0, 0, 0, 0, 0, 0, 0, //2
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 1, 0, 0, 0,
			  0, 1, 0, 0, 0, 0, 1, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0]
			,
			[ 0, 0, 0, 0, 0, 0, 0, 0, //3
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 1, 0, 0, 0, 0,
			  0, 1, 0, 0, 0, 0, 1, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0]
			,
			[ 0, 0, 0, 0, 0, 0, 0, 0, //4
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 1, 0, 0, 1, 0,
			  0, 1, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0]
			,
			[ 0, 0, 0, 0, 0, 0, 0, 0, //5
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 1, 0, 1, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 1, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0]
			,
			[ 0, 0, 0, 0, 0, 0, 0, 0, //6
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 1, 0, 0, 0, 0, 1, 0,
			  0, 0, 0, 1, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0]
		]
	]
]
}

if room = Pirate_Seas { //bridges are already handled
object_locations = [
	[
		[ // add spawn tables here
			[ 0, 0, 0, 0, 0, 0, 0, 0, //1
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0]
			//, add alternative spawn tables here
		]
		//, you can add additional spawn tables to separate objects if you want
	]
]
}

if room = Volcanic_Wasteland {
object_locations = [
	[
		[ // add spawn tables here
			[ 0, 0, 0, 0, 0, 0, 0, 0, //1
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0]
			//, add alternative spawn tables here
		]
		//, you can add additional spawn tables to separate objects if you want
	]
]
}

if room = Volcanic_Wasteland_Boss {
object_locations = [
	[
		[ // add spawn tables here
			[ 0, 0, 0, 0, 0, 0, 0, 0, //1
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0]
			//, add alternative spawn tables here
		]
		//, you can add additional spawn tables to separate objects if you want
	]
]
}

if room = Void_Dimension {
object_locations = [
	[
		[ // add spawn tables here
			[ 0, 0, 0, 0, 0, 0, 0, 0, //1
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0,
			  0, 0, 0, 0, 0, 0, 0, 0]
			//, add alternative spawn tables here
		]
		//, you can add additional spawn tables to separate objects if you want
	]
]
}

spawned_objects = false;
