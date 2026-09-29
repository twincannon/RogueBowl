extends PanelContainer
class_name Frame10Container

@onready var ball_labels: Array[Label] = [
	$VBoxContainer/HBoxContainer/Frame1,
	$VBoxContainer/HBoxContainer/Frame2,
	$VBoxContainer/HBoxContainer/Frame3,
]

# marks[0..2] = ball marks; _total = running total ("" while pending) - no label for it in the scene yet
func set_marks(marks: Array[String], _total: String) -> void:
	for i in ball_labels.size():
		ball_labels[i].text = marks[i]
