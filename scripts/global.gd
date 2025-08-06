extends Node

func has_object_stopped_moving(object:RigidBody3D) -> bool:
	const LINEAR_THRESHOLD := 0.05
	const ANGULAR_THRESHOLD := 0.05
	return object.linear_velocity.length() < LINEAR_THRESHOLD and object.angular_velocity.length() < ANGULAR_THRESHOLD
