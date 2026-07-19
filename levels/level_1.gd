extends LevelData

func _init() -> void:
	level_number = 1
	level_name = "Some Simple Maths"
	start_address = "0x04"
	malloc_budget = 0
	program_listing = "a = 3\nb = 4\nresult = a + b"
	
func get_rooms() -> Dictionary:
	return {
		"0x04": {
			"type" : "INTEGER",
			"value" : 0,
			"expected" : 7,
			"protected" : false,
			"note" : "result = a + b",
			"position": Vector3(0, 0, 0)
		},
		
		"0x08": {
			"type" : "INTEGER",
			"value" : 3,
			"expected" : 3,
			"protected" : true,
			"note" : "a = 3",
			"position": Vector3(12, 0, 0)
		},
		
		"0x0C": {
			"type" : "INTEGER",
			"value" : 4,
			"expected" : 4,
			"protected" : true,
			"note" : "b = 4",
			"position": Vector3(-12, 0, 0)
		}
	}
	
