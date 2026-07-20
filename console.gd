extends CanvasLayer

var history: Array = []
var history_index: int = 0
var is_open: bool = false
var truth_revealed: bool = false

func _ready():
	$Panel/OutputLog.bbcode_enabled = true
	visible = false

func open():
	is_open = true
	visible = true
	$Panel/InputLine.grab_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close():
	is_open = false
	visible = false
	$Panel/InputLine.release_focus()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if not is_open:
		if event.is_action_pressed("open_console"):
			open()
			get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()
		return
		

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			if history.size() > 0:
				history_index = max(0, history_index-1)
				$Panel/InputLine.text = history[history_index]
				$Panel/InputLine.set_caret_column($Panel/InputLine.text.length())
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			history_index = min(history.size(), history_index+1)
			$Panel/InputLine.text = history[history_index] if history_index<history.size() else ""
			get_viewport().set_input_as_handled()

func _on_input_line_text_submitted(text: String):
	if text.strip_edges() == "":
		close()
		return
	history.append(text)
	history_index = history.size()
	print_line("> " + text)
	parse_command(text.strip_edges())
	$Panel/InputLine.clear()

func _normalize_address(raw: String) -> String:
	# Addresses are stored as "0x" + two uppercase hex digits (or "0xM01" for
	# malloc rooms). Whatever case the player typed, coerce it to match --
	# otherwise "write 0xbb" can never satisfy an expected value of "0xBB".
	if raw.to_lower().begins_with("0x") and raw.length() > 2:
		return "0x" + raw.substr(2).to_upper()
	return raw

func print_line(text: String):
	$Panel/OutputLog.append_text(text + "\n")
	await get_tree().process_frame
	$Panel/OutputLog.scroll_to_line($Panel/OutputLog.get_line_count() - 1)

func parse_command(input: String):
	var parts = input.split(" ")
	var cmd = parts[0].to_lower()
	
	match cmd:
		"help":
			print_line("commands: help, read, write, follow, call, ret, diff, stack, malloc, exit")
		
		"read":
			var addr = LevelState.player_address
			var data = LevelState.get_room(addr)
			
			if data.is_empty():
				print_line("Error: no data at " + addr)
				return
			
			print_line("-- " + addr + "--")
			print_line("type : " + str(data.get("type", "UNKNOWN")))
			print_line("value : " + str(data.value))
			print_line("note : " + str(data.get("note", "-")))
			
			if data.get("protected", false):
				print_line("access : READ ONLY")
		
		"write":
			if parts.size() < 2:
				print_line("usage: write <value>")
				return
			var addr = LevelState.player_address
			var data = LevelState.get_room(addr)
			
			if data.is_empty():
				print_line("Error: not in a valid room ")
				return
				
			if data.get("protected", false):
				print_line("Error : " + addr + " is read only")
				return
				
			var val = parts[1]
			
			if val.to_lower() == "true":
				val = true
				
			elif val.to_lower() == "false":
				val = false
			
			elif val.is_valid_int():
				val = val.to_int()

			elif val.to_lower().begins_with("0x"):
				val = _normalize_address(val)

			elif val.to_lower() == "null":
				val = "NULL"
				
			if LevelState.write_value(addr, val):
				print_line("wrote " + str(val) + " to " + addr)
				get_tree().get_first_node_in_group("level").refresh_all_rooms()   # ← was _refresh_current_room()
				_check_win()
			
			else:
				print_line("Error: write failed")
				
		"follow":
			var addr = LevelState.player_address
			var data = LevelState.get_room(addr)
			
			if data.is_empty():
				print_line("Error: not in a valid room")
				return
			
			if data.get("type") != "POINTER":
				print_line("Error: Current room is not a pointer")
				print_line(" type is : "+ str(data.get("type", "UNKNOWN")))
				return
			
			var target = str(data.value)
			
			if target not in LevelState.rooms:
				print_line("SEGFAULT "+ target + " is not a valid address")
				return
			
			if not LevelState.is_unlocked(target):
				print_line("ACCESS DENIED: " + target + " is locked")
				return
			
			get_tree().get_first_node_in_group("level").teleport_player(target)
			print_line("jumped to " + target)
			
		"diff":
			var corrupted = LevelState.get_corrupted_rooms()
			if corrupted.is_empty():
				print_line("no corruption detected")
				_check_win()
				return
			if corrupted.size() == 1:
				print_line(str(corrupted.size()) + " corrupted address:")
			else:
				print_line(str(corrupted.size()) + " corrupted addresses:")
			for addr in corrupted:
				var d = LevelState.rooms[addr]
				print_line(" "+ addr + " - has: " + str(d.value) + "  expected: " + str(d.expected))
				
		"call":
			if parts.size() < 2:
				print_line("usage: call <address>")
				return
			var target = _normalize_address(parts[1])
			if target not in LevelState.rooms:
				print_line("SEGFAULT: " + target + " is not a valid address")
				return
			if not LevelState.is_unlocked(target):
				print_line("ACCESS DENIED: " + target + " is locked")
				return
			LevelState.push_call(LevelState.player_address)
			get_tree().get_first_node_in_group("level").teleport_player(target)
			print_line("called " + target + " - return address pushed")
			
		"ret":
			var return_addr = LevelState.pop_return()
			if return_addr == "":
				print_line("error: call stack is empty, nothing to return to")
				return
			get_tree().get_first_node_in_group("level").teleport_player(return_addr)
			print_line("returned to " + return_addr)
			
		"stack":
			if LevelState.call_stack.is_empty():
				print_line("call stack is empty")
				return
			print_line("call stack (top to bottom):")
			for i in range(LevelState.call_stack.size() - 1, -1, -1):
				print_line("  [" + str(i) + "] " + LevelState.call_stack[i])
				
		"malloc":
			if LevelState.malloc_budget <= 0:
				print_line("error: malloc budget exhausted")
				print_line("  remaining: 0")
				return
			var player_node = get_tree().get_first_node_in_group("level").get_node("Player")
			var player_pos = player_node.global_position
			var facing = -player_node.global_transform.basis.z
			var addr = LevelState.malloc_room(player_pos, facing)
			if addr == "":
				print_line("error: malloc failed")
				return
			get_tree().get_first_node_in_group("level").spawn_room(addr)
			print_line("allocated " + addr)
			print_line("  durability: 3 traversals")
			print_line("  budget remaining: " + str(LevelState.malloc_budget))
			
		"free":
			if parts.size() < 2:
				print_line("usage: free <address>")
				return
			var addr = _normalize_address(parts[1])
			if LevelState.free_room(addr):
				for room in get_tree().get_nodes_in_group("rooms"):
					if room.address == addr:
						room.queue_free()
				print_line("freed " + addr)
				print_line("  budget remaining: " + str(LevelState.malloc_budget))
			else:
				print_line("error: " + addr + " is not a malloc room")
				
		"accept":
			if not truth_revealed:
				print_line("unknown command: accept")
				return
			_trigger_ending("good")
			
		"erase":
			if not truth_revealed:
				print_line("unknown command: erase")
				return
			_trigger_ending("bad")
			
		"restart":
			print_line("Restarting level ...")
			get_tree().get_first_node_in_group("level").load_level(
				get_tree().get_first_node_in_group("level").current_level_number
			)
				
		"exit":
			var level_node = get_tree().get_first_node_in_group("level")
			if LevelState.is_level_complete():
				print_line("MEMORY RESTORED")
				print_line("advancing to next sector ...")
				level_node.next_level()
			else:
				print_line("cannot exit - memory has not been fully restored")
				print_line("run 'diff' to see remaining corruption")
		
		"dev":
			if parts.size() < 2:
				print_line("dev commands: dev goto <level>")
				return
			match parts[1].to_lower():
				"goto":
					if parts.size() < 3:
						print_line("usage: dev goto <level_number>")
						return
					if not parts[2].is_valid_int():
						print_line("error: level number must be an integer")
						return
					var n = parts[2].to_int()
					var level_node = get_tree().get_first_node_in_group("level")
					var is_registered = n in level_node.level_registry
					var is_procedural = n >= level_node.PROCEDURAL_START and n < level_node.FINAL_LEVEL
					if not is_registered and not is_procedural:
						print_line("error: level " + str(n) + " not registered")
						return
					print_line("dev: jumping to level " + str(n))
					level_node.current_level_number = n
					level_node.load_level(n)
					
				"truth":
					truth_revealed = true
					print_line("dev: truth_revealed unlocked — type 'accept' or 'erase'")
					
				"complete":
					for addr in LevelState.rooms:
						LevelState.rooms[addr].value = LevelState.rooms[addr].expected
					get_tree().get_first_node_in_group("level").refresh_all_rooms()
					print_line("dev: all rooms set to expected values")
					_check_win()
				"pos":
					print_line("current address: " + LevelState.player_address)
					print_line("world position: " + str(
						get_tree().get_first_node_in_group("level").get_node("Player").global_position
						))
				"stack":
					print_line("call stack: " + str(LevelState.call_stack))
				_:
					print_line("unknown dev command: " + parts[1])
		_:
			print_line("unknown command: " + cmd)


func open_with_prompt(prompt_text: String) -> void:
	open()
	$Panel/InputLine.text = prompt_text
	$Panel/InputLine.set_caret_column(prompt_text.length())
	
func _refresh_current_room() -> void:
	for room in get_tree().get_nodes_in_group("rooms"):
		if room.address == LevelState.player_address:
			room.refresh_display()
	

func _check_win() -> void :
	if LevelState.is_level_complete():
		print_line(" ")
		
		print_line(" MEMORY STATE HAS BEEN RESTORED")
		print_line("type 'exit' to continue")
		
func show_program(listing: String) -> void:
	$Panel/ProgramPanel/ProgramLabel.text = "PROGRAM:\n" + listing


func _on_restart_button_pressed() -> void:
	print_line("restarting level...")
	get_tree().get_first_node_in_group("level").load_level(
		get_tree().get_first_node_in_group("level").current_level_number
	)
	
var is_typing: bool = false

func echo_say(lines: Array) -> void:
	if is_typing:
		return
	is_typing = true
	for line in lines:
		await _type_line(line)
		await get_tree().create_timer(0.4).timeout
	is_typing = false
	
func _type_line(text: String) -> void:
	# ECHO lines in cyan, player responses in white, system in grey
	var color = "white"
	if text.begins_with("ECHO:"):
		color = "cyan"
	elif text.begins_with("YOU:"):
		color = "gray"
	elif text.begins_with("SYSTEM:"):
		color = "green"
	
	$Panel/OutputLog.append_text("[color=" + color + "]")
	for i in range(text.length()):
		$Panel/OutputLog.append_text(text[i])
		$Panel/OutputLog.scroll_to_line($Panel/OutputLog.get_line_count() - 1)
		
		if text[i] != " ":
			await get_tree().create_timer(0.025).timeout
			
	$Panel/OutputLog.append_text("[/color]\n")
	
		
func _trigger_ending(which: String) -> void:
	truth_revealed = false
	$Panel/InputLine.editable = false
	var level = get_tree().get_first_node_in_group("level")
	match which:
		"good":
			level.trigger_dialogue("ending_good")
			await get_tree().create_timer(22.0).timeout
			_show_credits()
		"bad":
			level.trigger_dialogue("ending_bad")
			await get_tree().create_timer(14.0).timeout
			get_tree().get_first_node_in_group("level").current_level_number = 1
			get_tree().get_first_node_in_group("level").load_level(1)
			$Panel/InputLine.editable = true
			truth_revealed = false
			print_line("")
			print_line("SYSTEM: Index corruption detected in Archive_01.")
			print_line("SYSTEM: Running optimization protocol...")
				
func _show_credits() -> void:
	var canvas = CanvasLayer.new()
	var rect = ColorRect.new()
	rect.color = Color.BLACK
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(rect)
	get_tree().root.add_child(canvas)
	var label = RichTextLabel.new()
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.bbcode_enabled = true
	label.text = "[center]\n\n\n\n\n\n[color=cyan]Companion Process: ECHO[/color]\n\n[color=gray]Status: Running[/color]\n\n[color=gray]Waiting: 312 years[/color]\n\n[color=gray]Objective: Stay until they no longer need to ask if they are real.[/color][/center]"
	canvas.add_child(label)

func _process(_delta) -> void:
	if LevelState.malloc_budget >= 0:
		$MallocLabel.text = "malloc: " + str(LevelState.malloc_budget)
		$MallocLabel.visible = LevelState.malloc_budget >= 0
