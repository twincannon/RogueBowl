extends OptionButton

func _ready() -> void:
	clear()
	for i in SaveGame.BALL_TYPES.size():
		add_item(SaveGame.BALL_TYPES[i].display_name, i)
	select(SaveGame.selected_ball_type_index)
	item_selected.connect(_on_item_selected)

func _on_item_selected(index: int) -> void:
	SaveGame.selected_ball_type_index = index
