extends LevelData
class_name LoreLevelData

@export var lore_text: Array = []
@export var room_color: Color = Color(0.2, 0.3, 0.5)
@export var is_lore: bool = true

func get_rooms() -> Dictionary:
	return {
		"LORE_ROOM": {
			"type": "LORE",
			"value": "exit",
			"expected": "exit",
			"protected": false,
			"note": "",
			"position": Vector3(0, 0, 0)
		}
	}
