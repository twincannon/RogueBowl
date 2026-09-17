extends RefCounted
class_name PlayerBall

var ball_type: BallType
var ball_scale: float = 1.0
var ball_vel_scale: float = 1.0

func _init(type: BallType) -> void:
	ball_type = type
