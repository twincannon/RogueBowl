extends Resource
class_name BallType

## Base ball type: pure data (all multipliers 1.0) and no-op hooks.
## Also directly usable as the "Default" ball - no subclass needed for it.
##
## NOTE: instances of this class (and its subclasses) are shared singletons
## (see SaveGame.BALL_TYPE_RESOURCES), not duplicated per throw. Subclasses that keep
## per-throw mutable state (e.g. a trail timer) must reset it in on_launch().
## This is only safe because exactly one Ball is ever in flight at a time -
## revisit if the game ever supports concurrent balls.

@export var display_name: String = "Default"

@export var mass_multiplier: float = 1.0
@export var scale_multiplier: float = 1.0
@export var velocity_multiplier: float = 1.0
@export var spin_grip_multiplier: float = 1.0
@export var visual_spin_multiplier: float = 1.0

## Called once when the ball is launched.
func on_launch(_ball: RigidBody3D) -> void:
	pass

## Called every physics tick while the ball is launched and not yet frozen.
func physics_tick(_ball: RigidBody3D, _delta: float) -> void:
	pass

## Called whenever the ball's body_entered signal fires (e.g. hits a pin).
func on_body_contact(_ball: RigidBody3D, _body: Node) -> void:
	pass
