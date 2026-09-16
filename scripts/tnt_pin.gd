extends BowlingPin
class_name TntPin

@export var blast_radius: float = 2.0
@export var blast_impulse_strength: float = 6.0
@export var self_launch_impulse: float = 3.0
@export var explosion_scene: PackedScene = preload("res://scenes/effects/explosion_burst.tscn")

var _ignited := false

func ignite() -> void:
	if _ignited:
		return
	_ignited = true
	pin_is_fallen = true
	delay_freeze(2.0)
	SaveGame.pins += 1  # this pin still counts as knocked down

	apply_central_impulse(Vector3.UP * self_launch_impulse * mass)
	_spawn_explosion_vfx()

	for node in get_tree().get_nodes_in_group("pins"):
		if node == self or not (node is BowlingPin):
			continue
		var other := node as BowlingPin
		var to_other := other.global_position - global_position
		var dist := to_other.length()
		if dist < 0.05 or dist > blast_radius:
			continue
		var falloff := 1.0 - dist / blast_radius
		other.apply_central_impulse((to_other / dist) * blast_impulse_strength * falloff * other.mass)
		other.delay_freeze(2.0)
		if other.has_method("ignite"):
			other.ignite()  # chain reaction - safe, ignite() is idempotent

func _spawn_explosion_vfx() -> void:
	var fx := explosion_scene.instantiate() as GPUParticles3D
	get_tree().current_scene.add_child(fx)
	fx.global_position = global_position
	get_tree().create_timer(fx.lifetime + 0.2).timeout.connect(fx.queue_free)
