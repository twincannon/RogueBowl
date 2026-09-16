extends BallType
class_name BlackHoleBallType

@export var pull_radius: float = 3.0
@export var pull_strength: float = 8.0  # m/s^2 at zero distance, falls off linearly to 0 at pull_radius

func physics_tick(ball: RigidBody3D, _delta: float) -> void:
	for node in ball.get_tree().get_nodes_in_group("pins"):
		if not (node is BowlingPin): #or node.pin_is_fallen:
			continue
		var pin := node as BowlingPin
		var to_ball := ball.global_position - pin.global_position
		var dist := to_ball.length()
		if dist < 0.05 or dist > pull_radius:
			continue
		var falloff := 1.0 - dist / pull_radius
		pin.apply_central_force((to_ball / dist) * pull_strength * falloff * pin.mass)
