extends HBoxContainer
class_name UpgradeButton

@export var button_text:String = ""
@export var cost:int = 0

func _ready():
	$Button.text = button_text
	$Label.text = str(cost)


func _on_button_pressed() -> void:
	if SaveGame.pins >= cost:
		SaveGame.pins -= cost
		match $Button.text:
			"Ball Size":
				SaveGame.ball_scale += 0.25
			"Ball Speed":
				SaveGame.ball_vel_scale += 0.25
			"Pin Count":
				SaveGame.pin_rows += 1
