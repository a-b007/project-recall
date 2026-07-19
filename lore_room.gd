extends Node3D

func init_lore(lore_level: LoreLevelData) -> void:
	$AmbientLight.light_color = lore_level.room_color

	var panels = [$Panel_1/PanelLabel, $Panel_2/PanelLabel, $Panel_3/PanelLabel]
	for i in range(min(lore_level.lore_text.size(), panels.size())):
		panels[i].text = lore_level.lore_text[i]

	$ExitTrigger.body_entered.connect(_on_exit_triggered)

func _on_exit_triggered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return
	get_tree().get_first_node_in_group("level").next_level()
