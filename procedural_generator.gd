extends Node


const TYPE_POINTER := "POINTER"
const TYPE_INTEGER := "INTEGER"
const TYPE_BOOL := "BOOL"


func generate(level_num: int) -> Dictionary:
	var params := _get_params(level_num)
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var ctx := {
		"params": params,
		"rng": rng,
		"graph": {},         # addr -> room data
		"edges": {},         # addr -> Array[addr], structural pointer edges
		"used": {},          # addr -> true, every address minted so far
		"pool": [],          # unused addresses ready to hand out
		"branch_roots": [],  # [{addr, parent}] for layout + bookkeeping
		"spine": [],
		"start": "",
	}

	_build_spine(ctx)
	_grow_branches(ctx)
	_apply_gate(ctx)
	_apply_corruption(ctx)
	_assign_positions(ctx)

	return ctx.graph


func _get_params(n: int) -> Dictionary:
	return {
		"level_num":        n,
		"corruption_count": min(2 + int(n * 0.6), 8),
		"graph_depth":      min(3 + int(n * 0.4), 8),
		"branch_chance":    min(0.15 + n * 0.05, 0.6),
		"max_branch_depth": min(1 + int(n * 0.25), 4),
		"converge_chance":  min(0.05 + n * 0.02, 0.25),
		"use_bool":         n >= 3,
		"use_call":         n >= 5,
		"use_malloc":       n >= 6,
		"malloc_budget":    1 if n >= 6 else 0,
		"use_null_trap":    n >= 8,
		"protected_count":  min(int(n * 0.3), 3),
	}

# ---------------------------------------------------------------------------
# Spine: the single walkable chain from start to a terminal value
# ---------------------------------------------------------------------------

func _build_spine(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.params
	var depth: int = max(2, params.graph_depth)

	var spine: Array = []
	for i in range(depth):
		spine.append(_take_address(ctx))

	ctx.start = spine[0]
	ctx.spine = spine

	for i in range(depth):
		var addr: String = spine[i]
		if i == depth - 1:
			ctx.graph[addr] = _make_leaf(ctx)
		else:
			_wire_pointer(ctx, addr, spine[i + 1], "spine")

	ctx.graph[ctx.start]["is_start"] = true

# ---------------------------------------------------------------------------
# Branches: side chains discovered via `diff`, reached via `call <address>`.
# Their tips can converge back onto an existing node instead of dead-ending,
# which is what turns this from a tree into a real DAG.
# ---------------------------------------------------------------------------

func _grow_branches(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.params
	if not params.use_call:
		return  # player hasn't been introduced to `call` yet -- keep it a plain chain

	var spine: Array = ctx.spine
	for i in range(spine.size() - 1):
		if ctx.rng.randf() > params.branch_chance:
			continue
		_grow_one_branch(ctx, spine[i])


func _grow_one_branch(ctx: Dictionary, parent_addr: String) -> void:
	var params: Dictionary = ctx.params
	var rng: RandomNumberGenerator = ctx.rng
	var length: int = rng.randi_range(1, max(1, params.max_branch_depth))

	var nodes: Array = []
	for i in range(length):
		nodes.append(_take_address(ctx))

	for i in range(nodes.size() - 1):
		_wire_pointer(ctx, nodes[i], nodes[i + 1], "branch")

	var tip: String = nodes[nodes.size() - 1]
	var converge_target: String = ""
	if params.converge_chance > rng.randf():
		converge_target = _pick_existing_address(ctx, nodes)

	if converge_target != "":
		_wire_pointer(ctx, tip, converge_target, "branch merge")
	else:
		ctx.graph[tip] = _make_leaf(ctx)

	ctx.graph[nodes[0]]["branch_of"] = parent_addr
	ctx.graph[nodes[0]]["call_only"] = true
	ctx.branch_roots.append({"addr": nodes[0], "parent": parent_addr})


func _pick_existing_address(ctx: Dictionary, exclude: Array) -> String:
	var candidates: Array = []
	for addr in ctx.graph.keys():
		if addr in exclude:
			continue
		candidates.append(addr)
	if candidates.is_empty():
		return ""
	return candidates[ctx.rng.randi_range(0, candidates.size() - 1)]

# ---------------------------------------------------------------------------
# Gate: one POINTER address is locked behind a BOOL room elsewhere in the
# graph. The gate is its own puzzle -- it starts corrupted about half the
# time, rather than always being pre-satisfied and doing nothing.
# ---------------------------------------------------------------------------

func _apply_gate(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.params
	if not params.use_bool:
		return

	var candidates: Array = []
	for addr in ctx.graph.keys():
		if addr == ctx.start:
			continue  # never lock the player's own entry point
		if ctx.graph[addr].get("type") == TYPE_POINTER:
			candidates.append(addr)
	if candidates.is_empty():
		return

	var locked_addr: String = candidates[ctx.rng.randi_range(0, candidates.size() - 1)]
	var gate_addr: String = _take_address(ctx)
	var starts_open: bool = ctx.rng.randf() < 0.5

	ctx.graph[gate_addr] = {
		"type": TYPE_BOOL,
		"value": starts_open,
		"expected": true,
		"protected": false,
		"note": "access gate for " + locked_addr,
		"call_only": true,
	}
	ctx.graph[locked_addr]["locked_by"] = {
		"address": gate_addr,
		"value": true,
	}
	ctx.branch_roots.append({"addr": gate_addr, "parent": locked_addr})

# ---------------------------------------------------------------------------
# Corruption
# ---------------------------------------------------------------------------

func _apply_corruption(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.params
	var rng: RandomNumberGenerator = ctx.rng
	var graph: Dictionary = ctx.graph

	# a handful of nodes are permanently read-only landmarks -- reliable
	# reference points that are never part of the puzzle themselves.
	var protectable: Array = []
	for addr in graph.keys():
		if addr != ctx.start and graph[addr].get("type") != TYPE_BOOL:
			protectable.append(addr)
	protectable.shuffle()
	for i in range(min(params.protected_count, protectable.size())):
		graph[protectable[i]].protected = true

	var corruptible: Array = []
	for addr in graph.keys():
		var d: Dictionary = graph[addr]
		if d.get("protected", false):
			continue
		if d.get("type") == TYPE_BOOL:
			continue  # gates get their own corruption logic in _apply_gate
		corruptible.append(addr)
	corruptible.shuffle()

	var count: int = min(params.corruption_count, corruptible.size())
	for i in range(count):
		var addr: String = corruptible[i]
		var d: Dictionary = graph[addr]
		match d.get("type"):
			TYPE_POINTER:
				if params.use_null_trap and rng.randf() < 0.35:
					d.value = "NULL"
				else:
					d.value = "0x%02X" % rng.randi_range(200, 254)
			TYPE_INTEGER:
				var wrong: int = d.expected
				var attempts := 0
				while wrong == d.expected and attempts < 10:
					wrong = rng.randi_range(0, 50)
					attempts += 1
				d.value = wrong

# ---------------------------------------------------------------------------
# Layout: BFS from the start along structural edges (not post-corruption
# values, which may point at garbage/NULL). Branch chains are laid out in
# their own lane near the spine node they hang off. Anything that somehow
# still lacks a position by the end gets one explicitly -- nothing is ever
# allowed to fall back to Vector3.ZERO and silently overlap another room.
# ---------------------------------------------------------------------------

func _assign_positions(ctx: Dictionary) -> void:
	var graph: Dictionary = ctx.graph
	if graph.is_empty():
		return

	var visited: Dictionary = {}
	_layout_from(ctx, ctx.start, 0, 0.0, 0.0, visited)

	var lane: int = 1
	for entry in ctx.branch_roots:
		var branch_addr: String = entry.addr
		if branch_addr in visited:
			continue
		var anchor: Vector3 = graph.get(entry.parent, {}).get("position", Vector3.ZERO)
		_layout_from(ctx, branch_addr, 0, anchor.x + lane * 10.0, anchor.z + 10.0, visited)
		lane += 1

	var stray: int = 0
	for addr in graph.keys():
		if not graph[addr].has("position"):
			graph[addr]["position"] = Vector3(-60.0 - stray * 6.0, 0, -40.0)
			stray += 1


func _layout_from(ctx: Dictionary, root: String, base_depth: int, x_offset: float, z_offset: float, visited: Dictionary) -> void:
	var graph: Dictionary = ctx.graph
	if root == "" or root not in graph or root in visited:
		return

	var depth_count: Dictionary = {}
	var queue: Array = [[root, base_depth]]
	while not queue.is_empty():
		var item: Array = queue.pop_front()
		var addr: String = item[0]
		var depth: int = item[1]
		if addr in visited or addr not in graph:
			continue
		visited[addr] = true

		var col: int = depth_count.get(depth, 0)
		depth_count[depth] = col + 1
		graph[addr]["position"] = Vector3(x_offset + col * 6.0, 0, z_offset + depth * 12.0)

		for child in ctx.edges.get(addr, []):
			if child not in visited:
				queue.append([child, depth + 1])

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_leaf(ctx: Dictionary) -> Dictionary:
	var v: int = ctx.rng.randi_range(1, 40)
	return {
		"type": TYPE_INTEGER,
		"value": v,
		"expected": v,
		"protected": false,
		"note": "terminal value",
	}


func _make_pointer(addr: String, target: String, tag: String) -> Dictionary:
	return {
		"type": TYPE_POINTER,
		"value": target,
		"expected": target,
		"protected": false,
		"note": "ptr -> " + target + " (" + tag + ")",
	}


func _wire_pointer(ctx: Dictionary, from_addr: String, to_addr: String, tag: String) -> void:
	ctx.graph[from_addr] = _make_pointer(from_addr, to_addr, tag)
	if not ctx.edges.has(from_addr):
		ctx.edges[from_addr] = []
	ctx.edges[from_addr].append(to_addr)


func _take_address(ctx: Dictionary) -> String:
	if ctx.pool.is_empty():
		ctx.pool = _generate_address_pool(12, ctx.used, ctx.rng)
		if ctx.pool.is_empty():
			# 256 possible byte addresses total -- exhausting them would need
			# an absurdly large level. Fail safe instead of crashing.
			push_warning("ProceduralGenerator: address space exhausted")
			return "0xFF"
	return ctx.pool.pop_back()


func _generate_address_pool(count: int, used: Dictionary, rng: RandomNumberGenerator) -> Array:
	var addrs: Array = []
	var attempts: int = 0
	var max_attempts: int = count * 20 + 50
	while addrs.size() < count and attempts < max_attempts:
		attempts += 1
		var n: int = rng.randi_range(0, 255)
		var addr: String = "0x%02X" % n
		if addr in used:
			continue
		used[addr] = true
		addrs.append(addr)
	return addrs
