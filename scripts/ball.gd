extends RigidBody3D

@onready var arrow := $Arrow

@export var spin_grip_factor: float = 1.0  # tune this - how much spin translates to curve

var launched := false

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4

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
	
#func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	#if state.get_contact_count() > 0:
		#var spin = angular_velocity
		## Sideways component of spin (around the vertical/forward axes)
		#var lateral_force = Vector3(spin.y, 0, spin.x) * spin_grip_factor
		#state.apply_central_force(lateral_force)
