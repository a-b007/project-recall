extends Node

func generate(level_num: int) -> Dictionary:
	var params = _get_params(level_num)
	var graph = _build_correct_graph(params)
	_apply_corruption(graph, params)
	_assign_positions(graph)
	return graph
	
func _get_params(n: int) -> Dictionary:
	return {
		"level_num":        n,
		"corruption_count": min(2 + int(n * 0.6), 8),
		"graph_depth":      min(2 + int(n * 0.4), 7),
		"branch_chance":    min(0.1 + n * 0.05, 0.5),
		"use_bool":         n >= 3,
		"use_call":         n >= 5,
		"use_malloc":       n >= 6,
		"malloc_budget":    1 if n >= 6 else 0,
		"use_null_trap":    n >= 8,
		"protected_count":  min(int(n * 0.3), 3),
	}
	
func _build_correct_graph(params: Dictionary) -> Dictionary:
	var graph = {}
	var addresses = _generate_addresses(params.graph_depth + 4)
	var depth = params.graph_depth
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var chain = []
	for i in range(depth):
		chain.append(addresses[i])
		var addr = chain[i]
		var is_last = (i == chain.size() - 1)
		
		if is_last:
			graph[addr] = {
				"type": "INTEGER",
				"value": rng.randi_range(1, 20),
				"expected": 0,
				"protected": false,
				"note": "terminal value"
			}
			graph[addr].expected = graph[addr].value
		
		else:
			graph[addr] = {
				"type": "POINTER",
				"value": chain[i + 1],
				"expected": chain[i + 1],
				"protected": false,
				"note": "ptr → " + chain[i + 1]
			}
	if params.use_bool and chain.size() >= 3:
		var gate_index = rng.randi_range(1, chain.size() - 2)
		var gate_addr = addresses[depth]
		graph[gate_addr] = {
			"type": "BOOL",
			"value": true,
			"expected": true,
			"protected": false,
			"note": "access gate"
		}
		graph[chain[gate_index]]["locked_by"] = {
			"address": gate_addr,
			"value": true
		}
	if params.branch_chance > rng.randf() and chain.size() >= 4:
		var branch_root = chain[rng.randi_range(1, chain.size() - 2)]
		var branch_addr = addresses[depth + 1]
		graph[branch_addr] = {
			"type": "INTEGER",
			"value": rng.randi_range(1, 30),
			"expected": 0,
			"protected": false,
			"note": "branch value"
		}
		graph[branch_addr].expected = graph[branch_addr].value
		if params.use_call:
			graph[branch_addr]["call_only"] = true
			
	return graph
		


func _apply_corruption(graph : Dictionary, params: Dictionary) -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var corruptible = []
	for addr in graph:
		var d = graph[addr]
		if not d.get("protected", false) and d.type != "BOOL":
			corruptible.append(addr)
	corruptible.shuffle()
	var count = min(params.corruption_count, corruptible.size())
	for i in range(count):
		var addr = corruptible[i]
		var d = graph[addr]
		match d.type:
			"POINTER":
				d.value = "0x%02X" % rng.randi_range(200, 254)
			"INTEGER":
				var wrong = d.expected
				while wrong == d.expected:
					wrong = rng.randi_range(0, 50)
				d.value = wrong
		if params.use_null_trap and corruptible.size() > 0:
			var trap_addr = corruptible[rng.randi_range(0, corruptible.size() - 1)]
			if graph[trap_addr].type == "POINTER":
				graph[trap_addr].value = "NULL"
	
func _assign_positions(graph : Dictionary):
	if graph.is_empty():
		return
	var start = graph.keys()[0]
	var visited = {}
	var queue = [[start, 0, 0]]
	var depth_count = {}
	while queue.size() > 0:
		var item = queue.pop_front()
		var addr =  item[0]
		var depth = item[1]
		var bx = item[2]
		if addr in visited or addr not in graph:
			continue
		visited[addr] = true
		if depth not in depth_count:
			depth_count[depth] = 0
		var x_offset = depth_count[depth] * 14
		depth_count[depth] += 1
		
		graph[addr]["position"] = Vector3(x_offset + bx, 0, depth * 15)
		
		var d = graph[addr]
		if d.type == "POINTER" and d.value in graph:
			queue.append([d.value, depth + 1, bx])
	
	
func _generate_addresses(count : int) -> Array:
	var addrs = []
	var used = {}
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	while addrs.size() < count:
		var n = rng.randi_range(0, 255)
		var addr = "0x%02X" % n
		if addr not in used:
			used[addr] = true
			addrs.append(addr)
	return addrs
		
