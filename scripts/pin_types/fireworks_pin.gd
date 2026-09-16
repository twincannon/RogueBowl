extends BowlingPin
class_name FireworksPin

@export var launch_speed: float = 5.0
@export var burst_delay: float = 0.6
@export var bonus_score: int = 5  # total score credited for this pin - replaces the normal +1, not added to it
@export var burst_scene: PackedScene = preload("res://scenes/effects/firework_burst.tscn")
@export var destroy_delay: float = 1.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _ignited := false

func ignite() -> void:
	if _ignited:
		return
	_ignited = true
	pin_is_fallen = true
	delay_freeze(2.0)  # see BowlingPin.delay_freeze() - avoids freezing at the toss's apex, where velocity is briefly ~0 for real

	# Disable collision for good. On a head-on hit, the ball-pin collision is
	# still being resolved by the physics solver this same step, and its own
	# contact response can overwrite the velocity we're about to set below -
	# that's why the launch sometimes didn't happen at all. This pin gets
	# destroyed shortly after bursting anyway, so there's no need to land.
	collision_shape.set_deferred("disabled", true)

	# Set velocity directly (rather than apply_central_impulse, which would
	# add to whatever velocity the ball's own collision just gave the pin)
	# so the launch is purely vertical along the global Y axis.
	linear_velocity = Vector3.UP * launch_speed
	get_tree().create_timer(burst_delay).timeout.connect(_burst)

func _burst() -> void:
	SaveGame.pins += bonus_score
	var fx := burst_scene.instantiate() as GPUParticles3D
	get_tree().current_scene.add_child(fx)
	fx.global_position = global_position
	fx.emitting = true  # don't rely on the scene's saved default
	get_tree().create_timer(fx.lifetime + 0.2).timeout.connect(fx.queue_free)

	visible = false
	get_tree().create_timer(destroy_delay).timeout.connect(queue_free)
