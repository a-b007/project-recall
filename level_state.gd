extends Node

var player_address : String = ""
var malloc_budget : int = 0
var rooms: Dictionary = {}
var current_level : LevelData = null
var call_stack : Array = []
var malloc_rooms: Dictionary = {}
var next_malloc_id: int = 0

func load_level (level : LevelData) -> void :
	current_level = level
	rooms = level.get_rooms()
	player_address = level.start_address
	malloc_budget = level.malloc_budget
	call_stack = []
	
func get_room(addr : String) -> Dictionary:
	return rooms.get(addr, {})
	
func push_call(addr: String) -> void:
	call_stack.append(addr)
	
func pop_return() -> String:
	if call_stack.is_empty():
		return ""
	return call_stack.pop_back()


func write_value(addr : String, val) -> bool:
	if addr not in rooms:
		return false
	if rooms[addr].get("protected", false):
		return false
	rooms[addr].value = val
	return true
	

func is_unlocked(addr: String) -> bool :
	var data = get_room(addr)
	if data.is_empty():
		return true
	var gate = data.get("locked_by", null)
	if gate == null:
		return true
	var gate_room = get_room(gate.address)
	if gate_room.is_empty():
		return true
	return str(gate_room.value) == str(gate.value)
	
func malloc_room(near_position: Vector3) -> String:
	if malloc_budget <= 0:
		return ""
	var addr = "0xM" + str(next_malloc_id).pad_zeros(2)
	next_malloc_id += 1
	malloc_budget -= 1
	malloc_rooms[addr] = {
		"type": "MALLOC",
		"value": "NULL",
		"expected": "NULL",
		"protected": false,
		"note": "temporary allocation",
		"position": near_position + Vector3(0, 0, 10),
		"durability": 3,
		"max_durability": 3
	}
	rooms[addr] = malloc_rooms[addr]
	return addr
	
func free_room(addr: String) -> bool:
	if addr not in malloc_rooms:
		return false
	malloc_rooms.erase(addr)
	rooms.erase(addr)
	malloc_budget += 1
	return true
	
func decrement_durability(addr: String) -> int:
	if addr not in malloc_rooms:
		return -1
	malloc_rooms[addr].durability -= 1
	rooms[addr].durability = malloc_rooms[addr].durability
	return malloc_rooms[addr].durability
	


func is_level_complete() -> bool:
	for addr in rooms:
		var r = rooms[addr]
		if str(r.value) != str(r.expected):
			return false
	return true
	
func get_corrupted_rooms() -> Array : 
	var result = []
	for addr in rooms:
		var r = rooms[addr]
		if str(r.value) != str(r.expected) : 
			result.append(addr)
	return result
	
