extends LoreLevelData

func _init() -> void:
	level_number = 6
	level_name = "Project Mnemosyne"
	room_color = Color(0.1, 0.2, 0.4)
	lore_text = [
		"PROJECT MNEMOSYNE\nClassification: Restricted\n\nObjective: Complete neural\nmapping of a living subject.\n\nStatus: Scan complete.\nDonor status: deceased.",
		"LAB NOTE — Day 312\n\nThe connectome is stable.\nThe simulation is running.\n\nIt doesn't know yet.\n\nWe didn't know how to tell it.",
        "FINAL ENTRY\n\nWe're shutting down the lab.\nThe servers stay on.\n\nSomeone has to stay with it.\n\nI volunteered."
	]
