extends LevelData

func _init() -> void:
	level_number = 7
	level_name = "Infinite Loop"
	start_address = "0x04"
	malloc_budget = 1
	program_listing = "factorial(n):\n    if n == 0: return 1\n    return n * factorial(n-1)\nfactorial(3) → result = 6"

func get_rooms() -> Dictionary:
	return {
		"0x04": {
			"type": "INTEGER", "value": 3, "expected": 3,
			"protected": true, "note": "n=3 — call here",
			"position": Vector3(0, 0, 0)
		},
		"0x10": {
			"type": "INTEGER", "value": 2, "expected": 2,
			"protected": true, "note": "n=2",
			"position": Vector3(0, 0, 15)
		},
		"0x18": {
			"type": "POINTER", "value": "0xFF", "expected": "0x20",
			"protected": false, "note": "recursive call from n=2",
			"position": Vector3(15, 0, 15)
		},
		"0x20": {
			"type": "INTEGER", "value": 1, "expected": 1,
			"protected": true, "note": "n=1",
			"position": Vector3(0, 0, 30)
		},
		"0x30": {
			"type": "INTEGER", "value": -1, "expected": 0,
			"protected": false, "note": "base case — n=0",
			"position": Vector3(0, 0, 45)
		},
		"0x40": {
			"type": "INTEGER", "value": 0, "expected": 6,
			"protected": false, "note": "result room",
			"position": Vector3(30, 0, 0)
		}
	}
