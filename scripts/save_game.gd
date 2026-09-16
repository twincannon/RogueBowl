extends Node

var pins := 0

# Upgrades
var ball_scale := 1.0
var ball_vel_scale := 1.0
var pin_rows := 4

# Ball types
var BALL_TYPES: Array[BallType] = [
	preload("res://resources/ball_types/default.tres"),
	preload("res://resources/ball_types/fireball.tres"),
	preload("res://resources/ball_types/black_hole.tres"),
]
var selected_ball_type_index := 0

func get_selected_ball_type() -> BallType:
	return BALL_TYPES[selected_ball_type_index]

# Pin types
var tnt_pin_chance := 0.1
var firework_pin_chance := 0.1
