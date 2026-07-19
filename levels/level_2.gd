extends LevelData

func _init() -> void:
	level_number = 2
	level_name = "The write way"
	start_address = "0x08"
	malloc_budget = 0
	program_listing = "x = 10\nptr = &x\n*ptr = x * 2"
	
func get_rooms() -> Dictionary:
	return {
		"0x08": {
			"type" : "POINTER",
			"value" : "0x0F",
			"expected" : "0x04",
			"protected" : false,
			"note" : "ptr = &x",
			"position" : Vector3(0,0,0)
		},
		
		"0x04" : {
			"type" : "INTEGER",
			"value" : 10,
			"expected" : 20,
			"protected" : false,
			"note" : "*ptr = x * 2",
			"position" : Vector3(0,0,15)
		},
		
		"0x0F" : {
			"type" : "NULL",
			"value" : "NULL",
			"expected" : "NULL",
			"protected": true,
			"note": "garbage address",
			"position" : Vector3(0,0,-15)
		}
		
	}
	
