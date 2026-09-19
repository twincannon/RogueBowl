extends BallType
class_name FireballType

func on_body_contact(_ball: RigidBody3D, body: Node) -> void:
	# Duck-typed against any pin that implements ignite() (TntPin, FireworksPin).
	if body is BowlingPin and body.has_method("ignite"):
		body.ignite()
