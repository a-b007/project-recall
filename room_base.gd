extends Node3D

@export var address: String = "0x00"

var player_in_range: bool = false

func _ready():
	add_to_group("rooms")
	$MapLabel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	$MapLabel.visible = false
	$ExitPortal.body_entered.connect(_on_portal_entered)
	$Device/InteractArea.body_entered.connect(_on_interact_area_entered)
	$Device/InteractArea.body_exited.connect(_on_interact_area_exited)
	
func _on_interact_area_entered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return
	player_in_range = true
	$Device/InteractLabel.visible = true
	
func _on_interact_area_exited(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return
	player_in_range = false
	$Device/InteractLabel.visible = false
	
func init_room() -> void:
	
	$AddressLabel.text = address
	$MapLabel.text = address
	$MapValueLabel.text = ""
	$MapValueLabel.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	$MapValueLabel.visible = false
	$Device/InteractLabel.visible = false
	refresh_display()
	
func get_spawn_position() -> Vector3:
	return $SpawnPoint.global_position
	
func refresh_display() -> void : 
	var data = LevelState.get_room(address)
	if data.is_empty():
		return
	
	$ValueLabel.text = str(data.value)
	
	var is_corrupt = str(data.value) != str(data.expected)
	$SpotLight3D.light_color = Color.RED if is_corrupt else Color.WHITE
	
	if data.get("protected", false):
		$ValueLabel.modulate = Color(1,1,0)
	else:
		$ValueLabel.modulate = Color.WHITE
		
	if data.get("type") == "POINTER":
		var target = str(data.value)
		var target_exists = target in LevelState.rooms
		var target_unlocked = target_exists and LevelState.is_unlocked(target)
		
		if target_exists and not target_unlocked:
			$ExitPortal/PortalLabel.text = "[LOCKED] -> " + target
			$ExitPortal/PortalMesh.visible = false
			$ExitPortal/DoorMesh.visible = true
		else:
			$ExitPortal/DoorMesh.visible = false
			$ExitPortal/PortalLabel.text = "-> " + target
			$ExitPortal/PortalMesh.visible = !is_corrupt
	
	else:
		$ExitPortal/PortalLabel.text = ""
		$ExitPortal/PortalMesh.visible = false
		$ExitPortal/DoorMesh.visible = false
		
	var type_str = data.get("type", "?")
	var corrupt_marker = "[X]" if is_corrupt else "[OK]"
	$MapValueLabel.text = type_str + ": " + str(data.value) + corrupt_marker
	$MapValueLabel.modulate = Color.RED if is_corrupt else Color.GREEN
	
	var is_malloc = address in LevelState.malloc_rooms
	if is_malloc:
		var dur = LevelState.malloc_rooms[address].get("durability", 0)
		$ValueLabel.text = "TEMP [" + str(dur) + "]"
		$SpotLight3D.light_color = Color(0.3, 0.8, 0.8)
	

func set_map_view(is_map : bool) -> void :
	$Ceiling.visible = !is_map
	$MapLabel.visible = is_map
	$MapValueLabel.visible = is_map
	
func set_active(active: bool) -> void:
	visible = active
	$ExitPortal/CollisionShape3D.disabled = !active
	
func _on_portal_entered(body : Node3D) -> void:
	if not body is CharacterBody3D:
		return
	var data = LevelState.get_room(address)
	if data.is_empty() or data.get("type") != "POINTER": 
		return
	var target = str(data.value)
	if target in LevelState.rooms and not LevelState.is_unlocked(target):
		return
	if address in LevelState.malloc_rooms:
		var remaining = LevelState.decrement_durability(address)
		refresh_display()
		if remaining <= 0:
			_collapse()
			return
			
	get_tree().get_first_node_in_group("level").teleport_player(str(data.value))
	
	
func _collapse() -> void:
	$SpotLight3D.light_color = Color.RED
	await get_tree().create_timer(0.5).timeout
	LevelState.free_room(address)
	queue_free()


func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range:
		return
	if event.is_action_pressed("interact"):
		var data = LevelState.get_room(address)
		if data.get("protected", false):
			get_tree().get_first_node_in_group("level") \
				.get_node("Player/Console").print_line("error: " + address + " is read-only")
			return
		get_tree().get_first_node_in_group("level") \
			.get_node("Player/Console").open_with_prompt("write ")
