extends HBoxContainer


var frame_scene = preload("res://scenes/ui/frame_container.tscn")
var frame10_scene = preload("res://scenes/ui/frame_container_frame10.tscn")

var frames:Array = []

func _ready() -> void:
	for i in 9:
		var new_frame = frame_scene.instantiate()
		add_child(new_frame)
		frames.append(new_frame)
	
	var new_frame10 = frame10_scene.instantiate()
	add_child(new_frame10)
	frames.append(new_frame10)

func update_scores():
	for f in frames.size():
		var marks: Array[String] = []
		for b in 3:
			marks.append(_mark(f, b))
		var total := BowlingGame.get_running_total(f)
		frames[f].set_marks(marks, "" if total < 0 else str(total))

# Scorecard text for one ball: X strike, / spare, - gutter, else the pin count. "" if not thrown yet.
func _mark(f: int, b: int) -> String:
	var ball := BowlingGame.get_throw(f, b)
	if ball == null:
		return ""
	if ball.is_strike():
		return "X"
	if ball.is_spare():
		return "/"
	if ball.pins_down == 0:
		return "-"
	return str(ball.pins_down)
