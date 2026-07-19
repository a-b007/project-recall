extends LevelData

func _init() -> void:
	level_number = 5
	level_name = "Corrupted Frame"
	start_address = "0x04"
	malloc_budget = 0
	program_listing = "function compute():\n    a = 3\n    b = 4\n    return a + b\nresult stored at 0x0C"

func get_rooms() -> Dictionary:
	return {
		"0x04": {
			"type": "POINTER", "value": "0x0C", "expected": "0x0C",
			"protected": false, "note": "entry — result goes to 0x0C",
			"position": Vector3(0, 0, 0)
		},
		"0x0C": {
			"type": "INTEGER", "value": 0, "expected": 7,
			"protected": false, "note": "result storage",
			"position": Vector3(0, 0, 15)
		},
		"0x20": {
			"type": "INTEGER", "value": 99, "expected": 3,
			"protected": false, "note": "variable a — call here",
			"position": Vector3(15, 0, 0)
		},
		"0x24": {
			"type": "INTEGER", "value": 4, "expected": 4,
			"protected": true, "note": "variable b — correct",
			"position": Vector3(30, 0, 0)
		},
		"0x28": {
			"type": "POINTER", "value": "0xFF", "expected": "0x0C",
			"protected": false, "note": "return address — corrupted",
			"position": Vector3(45, 0, 0)
		}
	}
