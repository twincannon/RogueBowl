extends RigidBody3D

@onready var arrow := $Arrow

var launched := false

func update_arrow(angle_degrees: float):
	arrow.rotation_degrees.y = angle_degrees

func launch(power:float, spin:float):
	arrow.visible = false
	launched = true
	set_freeze_enabled(false)
	
	var speed = power * SaveGame.ball_vel_scale
	var local_vel = Vector3(speed, 0.0, 0.0)
	var world_vel:Vector3 = global_transform.basis * local_vel
	set_axis_velocity(world_vel)

	const SPIN_BAR_MULTIPLIER_BY_VEL = 0.1
	var spin_multi_by_vel:float = world_vel.length() * SPIN_BAR_MULTIPLIER_BY_VEL
	angular_velocity.x = spin * (1.0 + spin_multi_by_vel)
