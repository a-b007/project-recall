extends Node3D

var is_map_view : bool = false
var map_scroll_speed : float = 15.0
var current_level_number = 1


@onready var game_camera : Camera3D = $Player/Camera3D
@onready var map_camera : Camera3D = $MapCamera
@onready var overlay = $Player/CorruptionOverlay/OverlayRect

var room_scene = preload("res://room_base.tscn")
var lore_room_scene = preload("res://lore_room.tscn")

var is_transitioning: bool = false

var level_registry : Dictionary = {
	1: preload("res://levels/level_1.gd"),
	2: preload("res://levels/level_2.gd"),
	3: preload("res://levels/lore_1.gd"),
	4: preload("res://levels/level_3.gd"),
	5: preload("res://levels/level_4.gd"),
	6: preload("res://levels/lore_2.gd"),
	7: preload("res://levels/level_5.gd"),
	8: preload("res://levels/level_6.gd"),
	9: preload("res://levels/level_7.gd"),
	10:preload("res://levels/lore_3.gd"),
	11:preload("res://levels/level_8.gd"),
}

const ProceduralLevel = preload("res://levels/level_procedural.gd")
const PROCEDURAL_START = 12
const FINAL_LEVEL = 15

func _ready() -> void:
	add_to_group("level")
	game_camera.current = true
	map_camera.current = false
	load_level(current_level_number)
	
func load_level(n : int) -> void:
	
	for room in get_tree().get_nodes_in_group("rooms"):
		room.queue_free()
		
	for room in get_tree().get_nodes_in_group("lore_rooms"):
		room.queue_free()
		
	var level: LevelData
		
	if n in level_registry:
		level = level_registry[n].new()
		
	elif n>=PROCEDURAL_START and n<FINAL_LEVEL:
		var proc = ProceduralLevel.new()
		proc.setup(n)
		level = proc
		
	else:
		push_error("no level for: " + str(n))
		return
		
	LevelState.load_level(level)
	
	if n >= PROCEDURAL_START and n < FINAL_LEVEL:
		await get_tree().process_frame
		var rel = n - PROCEDURAL_START
		if rel < 2:
			trigger_dialogue("echo_procedural_low")
		elif rel < 3:
			trigger_dialogue("echo_procedural_mid")
		else:
			trigger_dialogue("echo_procedural_deep")
	
	if level is LoreLevelData:
		var lore_room = lore_room_scene.instantiate()
		add_child(lore_room)
		lore_room.init_lore(level)
		await get_tree().process_frame
		$Player.global_position = lore_room.get_node("SpawnPoint").global_position
		return
		
	for addr in LevelState.rooms:
		spawn_room(addr)
		
	await get_tree().process_frame
	teleport_player(LevelState.player_address)
	trigger_dialogue("level_" + str(n) + "_start")
	
	
func spawn_room(addr: String) -> void:
	var data = LevelState.get_room(addr)
	var room = room_scene.instantiate()
	add_child(room)
	room.address = addr
	room.position = data.get("position", Vector3.ZERO)
	room.init_room()
	
func next_level() -> void :
	if is_transitioning:
		return
	
	is_transitioning = true
	
	
	await get_tree().create_timer(2.5).timeout
	
	if current_level_number == FINAL_LEVEL:
		_trigger_truth_reveal()
		is_transitioning = false
		return
	
	current_level_number += 1
	
	if current_level_number == 9:
		await transition_flash()
		load_level(current_level_number)
		await get_tree().create_timer(1.5).timeout
		trigger_dialogue("echo_first_contact")
		await get_tree().create_timer(5.0).timeout
		trigger_dialogue("echo_first_response")
		is_transitioning = false
		return
		
	if current_level_number == 12:
		await transition_flash()
		load_level(current_level_number)
		await get_tree().create_timer(1.0).timeout
		trigger_dialogue("echo_name_reveal")
		is_transitioning = false
		return
		
	if current_level_number == FINAL_LEVEL:
		await transition_flash()
		load_level(current_level_number)
		await get_tree().create_timer(1.0).timeout
		trigger_dialogue("echo_pause_moment")
		is_transitioning = false
		return
		
	await transition_flash()
	load_level(current_level_number)
	trigger_dialogue("level_" + str(current_level_number) + "_start")
	is_transitioning = false
	
func _trigger_truth_reveal() -> void:
	await transition_flash()
	$Player.set_physics_process(false)
	$Player.set_process_input(false)
	$Player/Console.truth_revealed = true
	trigger_dialogue("truth_reveal")
	
func transition_flash() -> void:
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	var canvas = CanvasLayer.new()
	canvas.add_child(overlay)
	add_child(canvas)
	var tween = create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.3)
	tween.tween_interval(0.2)
	tween.tween_property(overlay, "color", Color(0, 0, 0, 0), 0.3)
	await tween.finished
	canvas.queue_free()
	
func refresh_all_rooms() -> void:
	for room in get_tree().get_nodes_in_group("rooms"):
		var is_in_level = room.address in LevelState.rooms
		room.set_active(is_in_level)
		if is_in_level:
			room.refresh_display()
			


func teleport_player(target_address : String) -> void :
	if target_address not in LevelState.rooms:
		var console = $Player/Console
		console.print_line("SEGFAULT: " + target_address + " does not exist")
		return
		
	
	for room in get_tree().get_nodes_in_group("rooms"):
		if room.address == target_address:
			$Player.global_position = room.get_spawn_position()
			LevelState.player_address = target_address
			return
			
func trigger_dialogue(event: String) -> void:
	var lines = Dialogue.get_dialogue(event)
	if lines.is_empty():
		return
	$Player/Console.echo_say(lines)

	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_map"):
		is_map_view = !is_map_view
		game_camera.current = !is_map_view
		map_camera.current = is_map_view
		
		$Player.set_physics_process(!is_map_view)
		$Player.set_process_input(!is_map_view)
		
		if is_map_view:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			
		for room in get_tree().get_nodes_in_group("rooms"):
			room.set_map_view(is_map_view)
		
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not is_map_view:
		_update_corruption_overlay()
		return
	var dir = Input.get_vector("move_left", "move_right", "move_forward","move_back")
	map_camera.position.x += dir.x * map_scroll_speed * delta
	map_camera.position.z += dir.y * map_scroll_speed * delta
	
func _update_corruption_overlay() -> void:
	var corrupted = LevelState.get_corrupted_rooms().size()
	var total = LevelState.rooms.size()
	if total == 0:
		return
	var ratio = float(corrupted) / float(total)
	var mat = overlay.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("intensity", ratio * 0.6)
