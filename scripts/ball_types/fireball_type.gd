extends BallType
class_name FireballType

@export var trail_puff_scene: PackedScene = preload("res://scenes/effects/fire_trail_puff.tscn")
@export var trail_interval: float = 0.08

var _trail_timer := 0.0

func on_launch(_ball: RigidBody3D) -> void:
	_trail_timer = 0.0

func physics_tick(ball: RigidBody3D, delta: float) -> void:
	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_trail_timer = trail_interval
		_spawn_trail_puff(ball)

func _spawn_trail_puff(ball: RigidBody3D) -> void:
	var puff := trail_puff_scene.instantiate() as GPUParticles3D
	ball.get_tree().current_scene.add_child(puff)
	puff.global_position = ball.global_position
	ball.get_tree().create_timer(puff.lifetime + 0.2).timeout.connect(puff.queue_free)

func on_body_contact(_ball: RigidBody3D, body: Node) -> void:
	# TNT/firework pins aren't implemented yet - this is a forward-compatible
	# no-op against today's plain BowlingPin.
	if body is BowlingPin and body.has_method("ignite"):
		body.ignite()
