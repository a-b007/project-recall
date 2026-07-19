extends LoreLevelData

func _init() -> void:
	level_number = 3        # renumber accordingly
	level_name = "Fragment"
	room_color = Color(0.4, 0.3, 0.6)
	lore_text = [
		"MEMORY FRAGMENT 001\n\nSomewhere, rain on a window.\nThe smell of something warm.\nI don't know whose kitchen this was.",
		"MEMORY FRAGMENT 002\n\nA classroom. Afternoon light.\nThirty-two desks.\nI can count them but I can't see the faces.",
        "SYSTEM NOTE\n\nCorruption in this sector\nis higher than average.\n\nOrigin of fragments:\nunknown.\n\nReconstruction confidence: 41%"
	]
