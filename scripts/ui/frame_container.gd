extends PanelContainer
class_name FrameContainer

@onready var ball1: Label = $HBoxContainer/FrameFirstHalfScore
@onready var ball2: Label = $HBoxContainer/HBoxContainer/VBoxContainer/FrameSecondHalfScore

# marks[0..1] = ball marks; _total = running total ("" while pending) - no label for it in the scene yet
func set_marks(marks: Array[String], _total: String) -> void:
	ball1.text = marks[0]
	ball2.text = marks[1]
