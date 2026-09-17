extends HBoxContainer
class_name AddBallButton

@export var ball_type_id: SaveGame.BallTypeId
@export var cost: int = 0

func _ready() -> void:
	$Button.text = SaveGame.BALL_TYPE_RESOURCES[ball_type_id].display_name
	$Label.text = str(cost)

func _on_button_pressed() -> void:
	if SaveGame.pins >= cost:
		SaveGame.pins -= cost
		SaveGame.add_ball_to_collection(ball_type_id)
