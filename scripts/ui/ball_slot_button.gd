extends Button

@export var slot_index: int = 0

func _ready() -> void:
	_refresh_text()
	disabled = (slot_index == SaveGame.selected_hand_index)
	SaveGame.ball_selected.connect(_on_ball_selected)

func _on_ball_selected(hand_index: int) -> void:
	# Re-selecting the same slot (e.g. after buying an upgrade) refreshes its
	# stats text so it doesn't go stale while the ball is on display.
	_refresh_text()
	# The newly picked slot disables (its ball left the return for the lane);
	# any previously-picked slot re-enables (its ball is back in the return).
	disabled = (slot_index == hand_index)

func _refresh_text() -> void:
	var ball: PlayerBall = SaveGame.hand[slot_index]
	# Fixed-size text only - deliberately NOT scaling anything visually by
	# ball.ball_scale, so an upgraded ball doesn't look huge in the machine.
	text = "%s\nSize x%.2f  Spd x%.2f" % [ball.ball_type.display_name, ball.ball_scale, ball.ball_vel_scale]

func _pressed() -> void:
	SaveGame.select_ball(slot_index)
