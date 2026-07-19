extends Resource
class_name LevelData

@export var level_number: int = 1
@export var level_name : String = ""
@export var start_address : String = ""
@export var malloc_budget : int = 0
@export var program_listing : String = ""

func get_rooms() -> Dictionary:
	return {}
