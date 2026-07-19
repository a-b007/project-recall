extends LevelData

func _init() -> void:
	level_number = 3
	level_name = "Broken Chains"
	start_address = "0x04"
	malloc_budget = 0
	program_listing = "node_A -> node_B -> node_C -> node_D\nresult stored at node_D = 8"
	
func get_rooms() -> Dictionary:
	return {
		"0x04": {
			"type" : "POINTER",
			"value" : "0x10",
			"expected" : "0x10",
			"protected" : false,
			"note" : "node A",
			"position" : Vector3(0,0,0)
		},
		
		"0x10": {
			"type" : "POINTER",
			"value" : "0xBB",
			"expected" : "0x1C",
			"protected" : false,
			"note" : "node B",
			"position" : Vector3(0,0,15)
		},
		
		"0x1C": {
			"type" : "POINTER",
			"value" : "0xFF",
			"expected" : "0x28",
			"protected" : false,
			"note" : "node C",
			"position" : Vector3(0,0,30)
		},
		
		"0x28": {
			"type" : "INTEGER",
			"value" : 0,
			"expected" : 8,
			"protected" : false,
			"note" : "node D",
			"position" : Vector3(0,0,45)
		}
		
	}
	
