extends LevelData

func _init() -> void:
	level_number = 15
	level_name = "Core Index"
	start_address = "0x04"
	malloc_budget = 1
	program_listing = "CORE MEMORY INDEX\n[partial corruption — some lines unreadable]\n\nif (gate):\n    left  = process_L(5)     // L: x * 2\n    right = process_R(???)   // backing memory freed — reallocate\nfinal = left + right"

func get_rooms() -> Dictionary:
	return {
		"0x04": {
			"type": "BOOL", "value": true, "expected": false,
			"protected": false,
			"note": "gate — inverted. TRUE blocks both branches.",
			"position": Vector3(0, 0, 0)
		},
		"0x08": {
			"type": "POINTER", "value": "0x0C", "expected": "0x0C",
			"protected": false, "note": "entry to left branch",
			"locked_by": {"address": "0x04", "value": false},
			"position": Vector3(-15, 0, 15)
		},
		"0x0C": {
			"type": "INTEGER", "value": 0, "expected": 10,
			"protected": false, "note": "process_L(5) = 5*2",
			"position": Vector3(-15, 0, 30)
		},
		"0x10": {
			"type": "POINTER", "value": "0xFF", "expected": "0xM00",
			"protected": false,
			"note": "entry to right branch — original backing storage was freed. malloc a replacement and point here.",
			"locked_by": {"address": "0x04", "value": false},
			"position": Vector3(15, 0, 15)
		},
		"0x18": {
			"type": "POINTER", "value": "0x04", "expected": "NULL",
			"protected": false,
			"note": "TRAP — circular pointer back to gate",
			"position": Vector3(15, 0, 45)
		},
		"0x30": {
			"type": "INTEGER", "value": 0, "expected": 29,
			"protected": false, "note": "final = left + right — infer right from final=29, left=10",
			"position": Vector3(0, 0, 60)
		}
	}
