extends RigidBody3D

@onready var arrow := $Arrow
@onready var ball_shape: CollisionShape3D = $BallShape

@export var spin_grip_factor: float = 0.5  # lateral curve accel (m/s^2 per unit of spin), independent of ball speed
@export var visual_spin_scale: float = 0.5  # cosmetic english on top of the real rolling spin

var launched := false
var spin_input := 0.0

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4

func update_arrow(angle_degrees: float):
	arrow.rotation_degrees.y = angle_degrees

func launch(power:float, spin:float):
	arrow.visible = false
	launched = true
	spin_input = spin
	set_freeze_enabled(false)

	var speed = power * SaveGame.ball_vel_scale
	var local_vel = Vector3(speed, 0.0, 0.0)
	var world_vel:Vector3 = global_transform.basis * local_vel
	set_axis_velocity(world_vel)

	# Real no-slip rolling angular velocity (axis perpendicular to travel
	# direction) so the ball rolls down the lane instead of sliding.
	var radius:float = (ball_shape.shape as SphereShape3D).radius * ball_shape.scale.x
	var roll_velocity := world_vel.cross(Vector3.UP) / radius

	# Small amount of visible "english" around the vertical axis - the
	# actual curve of the trajectory comes from _integrate_forces below,
	# not from this angular velocity.
	angular_velocity = roll_velocity + Vector3.UP * spin_input * visual_spin_scale

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if not launched or is_zero_approx(spin_input) or state.get_contact_count() == 0:
		return

	var horizontal_vel := Vector3(state.linear_velocity.x, 0.0, state.linear_velocity.z)
	if horizontal_vel.length() < 0.05:
		return

	# Curve force perpendicular to the ball's current direction of travel.
	# Scaled by mass but not by speed, so a given spin value curves the ball
	# by the same amount whether it was thrown soft or very hard - a harder
	# throw just spends less time on the lane for the curve to build up.
	var travel_dir := horizontal_vel.normalized()
	var lateral_dir := travel_dir.cross(Vector3.UP)
	state.apply_central_force(lateral_dir * spin_input * spin_grip_factor * mass)
