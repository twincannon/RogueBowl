extends RigidBody3D
class_name Ball

@onready var arrow := $Arrow
@onready var ball_shape: CollisionShape3D = $BallShape

@export var spin_grip_factor: float = 0.5  # lateral curve accel (m/s^2 per unit of spin), independent of ball speed
@export var visual_spin_scale: float = 0.5  # cosmetic english on top of the real rolling spin
@export var ball_type: BallType = preload("res://resources/ball_types/default.tres")
@export var vel_scale_multiplier: float = 1.0

signal on_ball_selected

var launched := false
var spin_input := 0.0

var is_active_ball:bool = true: #if this is our ball that is ready to be launched
	set(is_active):
		is_active_ball = is_active
		$Arrow.visible = is_active

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	ball_type.on_body_contact(self, body)

func _physics_process(delta: float) -> void:
	if launched and not is_freeze_enabled():
		ball_type.physics_tick(self, delta)

func update_arrow(angle_degrees: float):
	arrow.rotation_degrees.y = angle_degrees

func launch(power:float, spin:float):
	arrow.visible = false
	launched = true
	spin_input = spin
	set_freeze_enabled(false)
	ball_type.on_launch(self)

	var speed = power * vel_scale_multiplier * ball_type.velocity_multiplier
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
	angular_velocity = roll_velocity + Vector3.UP * spin_input * visual_spin_scale * ball_type.visual_spin_multiplier

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
	state.apply_central_force(lateral_dir * spin_input * spin_grip_factor * ball_type.spin_grip_multiplier * mass)


func _on_input_event(camera: Node, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	if !is_active_ball and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		on_ball_selected.emit()
