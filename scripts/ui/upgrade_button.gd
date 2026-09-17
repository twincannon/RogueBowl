extends HBoxContainer
class_name UpgradeButton

@export var button_text:String = ""
@export var cost:int = 0

func _ready():
	$Button.text = button_text
	$Label.text = str(cost)


func _on_button_pressed() -> void:
	var is_ball_upgrade:bool = $Button.text == "Ball Size" or $Button.text == "Ball Speed"
	if is_ball_upgrade and SaveGame.selected_hand_index == -1:
		return  # nothing selected to upgrade

	if SaveGame.pins >= cost:
		SaveGame.pins -= cost
		match $Button.text:
			"Ball Size":
				SaveGame.hand[SaveGame.selected_hand_index].ball_scale += 0.25
			"Ball Speed":
				SaveGame.hand[SaveGame.selected_hand_index].ball_vel_scale += 0.25
			"Pin Count":
				SaveGame.pin_rows += 1

		if is_ball_upgrade:
			# Respawn the selected ball so the new stat is visible immediately.
			SaveGame.select_ball(SaveGame.selected_hand_index)
