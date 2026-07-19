extends LevelData

func _init() -> void:
	level_number = 4
	level_name = "Gated Access"
	start_address = "0x04"
	malloc_budget = 0
	program_listing = "if (ready):\n    process(data)\nready should be true"

func get_rooms() -> Dictionary:
	return {
		"0x04": {
			"type": "BOOL", "value": false, "expected": true,
			"protected": false, "note": "ready flag",
			"position": Vector3(0, 0, 0)
		},
		"0x08": {
			"type": "POINTER", "value": "0x14", "expected": "0x14",
			"protected": false, "note": "entry point to data",
			"position": Vector3(0, 0, 15)
		},
		"0x14": {
			"type": "POINTER", "value": "0xCC", "expected": "0x20",
			"protected": false, "note": "data chain",
			"locked_by": {"address": "0x04", "value": true},
			"position": Vector3(0, 0, 30)
		},
		"0x20": {
			"type": "INTEGER", "value": 0, "expected": 42,
			"protected": false, "note": "process(data) result",
			"position": Vector3(0, 0, 45)
		}
	}
