extends LevelData

func _init() -> void:
	level_number = 6
	level_name = "Isolated Sectors"
	start_address = "0x04"
	malloc_budget = 2
	program_listing = "struct_A.ready = true\nstruct_A.value = 15\nstruct_B.value = struct_A.value + 10"

func get_rooms() -> Dictionary:
	return {
		"0x04": {
			"type": "POINTER", "value": "0x08", "expected": "0x08",
			"protected": false, "note": "entry to struct_A",
			"position": Vector3(0, 0, 0)
		},
		"0x08": {
			"type": "BOOL", "value": false, "expected": true,
			"protected": false, "note": "struct_A.ready",
			"position": Vector3(0, 0, 15)
		},
		"0x0C": {
			"type": "INTEGER", "value": 0, "expected": 15,
			"protected": false, "note": "struct_A.value",
			"locked_by": {"address": "0x08", "value": true},
			"position": Vector3(0, 0, 30)
		},
		"0x30": {
			"type": "INTEGER", "value": 5, "expected": 5,
			"protected": true, "note": "struct_B.base",
			"position": Vector3(40, 0, 15)
		},
		"0x34": {
			"type": "POINTER", "value": "0xFF", "expected": "0x38",
			"protected": false, "note": "struct_B chain",
			"position": Vector3(40, 0, 30)
		},
		"0x38": {
			"type": "INTEGER", "value": 0, "expected": 25,
			"protected": false, "note": "struct_B.value",
			"position": Vector3(40, 0, 45)
		}
	}
