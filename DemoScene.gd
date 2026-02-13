extends Node3D

var player_scene = preload("res://FPSController/FPSController.tscn")

@onready var dungeon_generator = %DungeonGenerator3D

var blue_red = [
	preload("res://addons/SimpleDungeons/sample_dungeons/custom_random_room_function_example/blue_room.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/custom_random_room_function_example/red_room.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/custom_random_room_function_example/stairs.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/custom_random_room_function_example/corridor.tscn"),
]
var rgsdev = [
	preload("res://addons/SimpleDungeons/sample_dungeons/lowpoly_kit_1_rooms/bridge_room.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/lowpoly_kit_1_rooms/entrance_room.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/lowpoly_kit_1_rooms/living_room.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/lowpoly_kit_1_rooms/spike_hallway.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/lowpoly_kit_1_rooms/trap_room.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/lowpoly_kit_1_rooms/treasure_room.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/lowpoly_kit_1_rooms/stair.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/lowpoly_kit_1_rooms/corridor.tscn"),
]
var devtextures = [
	preload("res://addons/SimpleDungeons/sample_dungeons/with_dev_textures_rooms/bridge_room.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/with_dev_textures_rooms/entrance_room.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/with_dev_textures_rooms/living_room.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/with_dev_textures_rooms/stair.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/with_dev_textures_rooms/corridor.tscn"),
]
var mansion = [
	preload("res://addons/SimpleDungeons/sample_dungeons/mansion/rooms/bedroom.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/mansion/rooms/living_room.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/mansion/rooms/stair.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/mansion/rooms/corridor.tscn"),
]
var terrarium = [
	preload("res://addons/SimpleDungeons/sample_dungeons/terrarium/green_room.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/terrarium/stair.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/terrarium/corridor.tscn"),
]
var flat_wide = [
	preload("res://addons/SimpleDungeons/sample_dungeons/flat_wide_dungeon/living_room.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/flat_wide_dungeon/entrance_room.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/flat_wide_dungeon/bridge_room.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/lowpoly_kit_1_rooms/stair.tscn"),
	preload("res://addons/SimpleDungeons/sample_dungeons/flat_wide_dungeon/corridor.tscn"),
]

var names = {
	blue_red: "Custom room placement demo",
	rgsdev: "Dungeon Kit by rgsdev",
	devtextures: "Dev texture example",
	mansion: "Mansion",
	terrarium: "Terrarium",
	flat_wide: "Flat wide dungeon with rgsdev kit"
}

func _ready():
	for name in names.values():
		%OptionButtonDungeons.add_item(name)
	%DungeonGenerator3D.done_generating.connect(_on_dungeon_done_generating)
	%DownloadDungeonJsonButton.disabled = true
	%Seed.value = randi()
	regenerate()

func _update_props():
	%CamOrbitCenter.auto_rotate = %AutoRotateCheckBox.button_pressed
	%DungeonGenerator3D.visualize_generation_wait_between_iterations = %WaitMsRange.value
	%DungeonGenerator3D.show_debug_in_game = %ShowDebugCheckBox.button_pressed
	if %DungeonGenerator3D.is_currently_generating:
		return
	%DungeonGenerator3D.visualize_generation_progress = %WaitMsRange.value > 0
	%DungeonGenerator3D.dungeon_size = Vector3i(%X.value, %Y.value, %Z.value)

var prev = null
func _process(delta):
	_update_props()
	%GUI.visible = Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED
	if Input.get_mouse_mode() != prev:
		prev = Input.get_mouse_mode()
		for c in %GUI.find_children("*", "Control"):
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				c.grab_focus()
				c.release_focus()
			c.focus_mode = Control.FOCUS_NONE if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Control.FOCUS_CLICK

var mansion_exterior
var mansion_entrance_room
func cleanup_mansion():
	if mansion_entrance_room:
		mansion_entrance_room.get_parent().remove_child(mansion_entrance_room)
		mansion_entrance_room.queue_free()
		mansion_entrance_room = null
	if mansion_exterior:
		mansion_exterior.get_parent().remove_child(mansion_exterior)
		mansion_exterior.queue_free()
		mansion_exterior = null

func setup_mansion():
	mansion_exterior = preload("res://addons/SimpleDungeons/sample_dungeons/mansion/house_exterior.tscn").instantiate()
	add_child(mansion_exterior)
	mansion_exterior.dungeon_generator = %DungeonGenerator3D
	mansion_entrance_room = preload("res://addons/SimpleDungeons/sample_dungeons/mansion/mansion_entrance_room.tscn").instantiate()
	%DungeonGenerator3D.add_child(mansion_entrance_room)
	mansion_entrance_room.set_position_by_grid_pos(Vector3i(%DungeonGenerator3D.dungeon_size.x / 2 - 1,2,999))

func regenerate():
	if %DungeonGenerator3D.is_currently_generating:
		print("Aborting...")
		%DungeonGenerator3D.abort_generation()
		print("Aborted successfully")
	%DownloadDungeonJsonButton.disabled = true
	
	cleanup_mansion()
	var n = %OptionButtonDungeons.get_item_text(%OptionButtonDungeons.get_selected_id())
	var d_arr = names.find_key(n).slice(0)
	var corridor = d_arr.pop_back()
	var xyz = Vector3i(%X.value, %Y.value, %Z.value)
	if xyz.y == 1:
		d_arr.pop_back() # Remove stair room, made it second to last in all. Some have multiple 2 floor rooms but can try to make all generate if only 1 height
		if names.find_key(n) == rgsdev:
			# Also remove 2 floor rooms for rgsdev
			d_arr.pop_back() # Treasure room
			d_arr.pop_back() # Trap room
			d_arr.pop_back() # Spike room
	var room_scenes : Array[PackedScene] = []
	room_scenes.assign(d_arr)
	%DungeonGenerator3D.corridor_room_scene = corridor
	%DungeonGenerator3D.room_scenes = room_scenes
	
	%DungeonGenerator3D.custom_get_rooms_function = custom_get_rand_rooms if n == "Custom room placement demo" else null
	
	if n == "Mansion":
		setup_mansion()
	
	_update_props()
	%DungeonGenerator3D.generate(%Seed.value)

func _on_dungeon_done_generating():
	%DownloadDungeonJsonButton.disabled = false

func _on_download_dungeon_json_button_pressed():
	if %DungeonGenerator3D.is_currently_generating:
		print("Dungeon is still generating. Try again in a moment.")
		return
	var json_payload := _build_dungeon_layout_json_payload()
	var json_text := JSON.stringify(json_payload, "\t")
	var file_name := "dungeon_layout_%s.json" % Time.get_unix_time_from_system()
	if OS.has_feature("web"):
		if not Engine.has_singleton("JavaScriptBridge"):
			push_error("JavaScriptBridge singleton not available on this web export template.")
			return
		var js = JavaScriptBridge
		var encoded_data = Marshalls.raw_to_base64(json_text.to_utf8_buffer())
		js.eval("""
			(function(){
				const bytes = Uint8Array.from(atob('%s'), c => c.charCodeAt(0));
				const blob = new Blob([bytes], { type: 'application/json' });
				const url = URL.createObjectURL(blob);
				const a = document.createElement('a');
				a.href = url;
				a.download = '%s';
				document.body.appendChild(a);
				a.click();
				a.remove();
				URL.revokeObjectURL(url);
			})();
		""" % [encoded_data, file_name])
		print("Downloaded dungeon JSON to browser.")
		return
	var save_path := "user://%s" % file_name
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write JSON file to %s" % save_path)
		return
	file.store_string(json_text)
	print("Saved dungeon JSON to ", ProjectSettings.globalize_path(save_path))

func _build_dungeon_layout_json_payload() -> Dictionary:
	var rooms : Array = []
	var rooms_container := %DungeonGenerator3D.get_node_or_null("RoomsContainer")
	if rooms_container:
		for room in rooms_container.get_children():
			if room is DungeonRoom3D:
				rooms.push_back({
					"name": room.name,
					"scene_path": room.scene_file_path,
					"grid_pos": [room.get_grid_pos().x, room.get_grid_pos().y, room.get_grid_pos().z],
					"room_rotations": room.room_rotations,
					"size_in_voxels": [room.size_in_voxels.x, room.size_in_voxels.y, room.size_in_voxels.z],
					"global_position": [room.global_position.x, room.global_position.y, room.global_position.z]
				})
	return {
		"seed": int(%Seed.value),
		"dungeon_size": [%DungeonGenerator3D.dungeon_size.x, %DungeonGenerator3D.dungeon_size.y, %DungeonGenerator3D.dungeon_size.z],
		"voxel_scale": [%DungeonGenerator3D.voxel_scale.x, %DungeonGenerator3D.voxel_scale.y, %DungeonGenerator3D.voxel_scale.z],
		"room_count": rooms.size(),
		"rooms": rooms
	}


func _on_generate_with_new_seed_button_pressed():
	%Seed.value = randi()
	regenerate()

func custom_get_rand_rooms(room_instances : Array[DungeonRoom3D], rng_seeded : RandomNumberGenerator) -> Array[DungeonRoom3D]:
	var num_blue_rooms : int = 30
	var num_red_rooms : int = 30
	var blue_room = room_instances.filter(func(r): return r.name == "BlueRoom")[0]
	var red_room = room_instances.filter(func(r): return r.name == "RedRoom")[0]
	var rooms : Array[DungeonRoom3D] = []
	while num_red_rooms > 0:
		var inst = red_room.create_clone_and_make_virtual_unless_visualizing()
		rooms.push_back(inst)
		# Set room_rotations before set_position_by_grid_pos as it is set by AABB positon. May change when rotated.
		inst.room_rotations = rng_seeded.randi()
		inst.set_position_by_grid_pos(
			Vector3i(
				(rng_seeded.randi() % dungeon_generator.dungeon_size.x) / 2,
				rng_seeded.randi() % dungeon_generator.dungeon_size.y,
				rng_seeded.randi() % dungeon_generator.dungeon_size.z))
		num_red_rooms -= 1
	while num_blue_rooms > 0:
		var inst = blue_room.create_clone_and_make_virtual_unless_visualizing()
		rooms.push_back(inst)
		# Set room_rotations before set_position_by_grid_pos as it is set by AABB positon. May change when rotated.
		inst.room_rotations = rng_seeded.randi()
		inst.set_position_by_grid_pos(
			Vector3i(
				(rng_seeded.randi() % dungeon_generator.dungeon_size.x) / 2 + dungeon_generator.dungeon_size.x / 2,
				rng_seeded.randi() % dungeon_generator.dungeon_size.y,
				rng_seeded.randi() % dungeon_generator.dungeon_size.z))
		num_blue_rooms -= 1
	return rooms

var player
func _on_spawn_player_button_pressed():
	if player and is_instance_valid(player): return
	var spawn_points = get_tree().get_nodes_in_group("player_spawn_point")
	if spawn_points.size() == 0: return
	player = player_scene.instantiate()
	spawn_points.pick_random().add_child(player)
	for cam in player.find_children("*", "Camera3D"):
		cam.current = true
