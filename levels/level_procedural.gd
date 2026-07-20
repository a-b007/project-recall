extends LevelData

var _level_num: int = 0

func setup(n: int) -> void:
	_level_num = n
	level_number = n
	level_name = "Memory Fragment %02d" % n
	start_address = ""
	malloc_budget = ProceduralGenerator._get_params(n).malloc_budget
	program_listing = _generate_listing(n)

func get_rooms() -> Dictionary:
	var rooms = ProceduralGenerator.generate(_level_num)
	if rooms.is_empty():
		return {}
	start_address = ""
	for addr in rooms:
		if rooms[addr].get("is_start", false):
			start_address = addr
			break
	if start_address == "":
		start_address = rooms.keys()[0]  # fallback, shouldn't be reachable
	return rooms

func _generate_listing(n: int) -> String:
	# generates a plausible pseudocode snippet based on what mechanics are active
	var params = ProceduralGenerator._get_params(n)
	var lines = []
	lines.append("MEMORY FRAGMENT — origin: unknown")
	lines.append("reconstruction confidence: %d%%" % max(10, 80 - n * 3))
	if params.use_bool:
		lines.append("\nif (gate):")
		lines.append("    process(data)")
	elif params.use_call:
		lines.append("\nfunction compute(x):")
		lines.append("    return transform(x)")
	else:
		lines.append("\nptr = &data")
		lines.append("result = *ptr")
	if params.malloc_budget > 0:
		lines.append("\n[malloc budget: %d]" % params.malloc_budget)
	return "\n".join(lines)
