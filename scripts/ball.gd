extends RigidBody3D
class_name Ball

@onready var arrow := $Arrow
@onready var ball_shape: CollisionShape3D = $BallShape

@export var spin_grip_factor: float = 0.5  # lateral curve accel (m/s^2 per unit of spin), independent of ball speed
@export var visual_spin_scale: float = 0.5  # cosmetic english on top of the real rolling spin
@export var vel_scale_multiplier: float = 1.0

@export var ball_type: BallType = preload("res://resources/ball_types/default.tres"):
	set(new_type):
		ball_type = new_type
		_update_visual()
		_update_collision_shape()

signal on_ball_selected

var launched := false
var spin_input := 0.0
var visual_instance: Node3D = null  # the current type's custom visual, if any - read by main.gd to scale it with upgrades
var _default_collision_shape: Shape3D  # captured lazily, from whatever $BallShape.shape was before any override

func _update_visual() -> void:
	if visual_instance:
		visual_instance.queue_free()
		visual_instance = null
	if ball_type and ball_type.visual_scene:
		visual_instance = ball_type.visual_scene.instantiate()
		add_child(visual_instance)
		$BallMesh.visible = false   # the custom visual replaces the plain sphere...
	else:
		$BallMesh.visible = true    # ...falls back to it when a type has no visual_scene (e.g. Default)

func _update_collision_shape() -> void:
	if _default_collision_shape == null:
		_default_collision_shape = $BallShape.shape  # capture the original sphere, once, before any override
	$BallShape.shape = ball_type.collision_shape if (ball_type and ball_type.collision_shape) else _default_collision_shape

var is_active_ball:bool = true: #if this is our ball that is ready to be launched
	set(is_active):
		is_active_ball = is_active
		$Arrow.visible = is_active
		$SpeedLabel.visible = !is_active
		$SizeLabel.visible = !is_active
		$NameLabel.visible = !is_active

func update_text_stats(ball:PlayerBall):
	$SpeedLabel.text = "Speed: " + str(ball.ball_vel_scale) + "x"
	$SizeLabel.text = "Size: " + str(ball.ball_scale) + "x"
	$NameLabel.text = ball.ball_type.display_name

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
	# direction) so the ball rolls down the lane instead of sliding. A type
	# with a custom collision_shape (e.g. an icosahedron) isn't a true roller,
	# so it uses an authored approximate radius instead of deriving an exact
	# one - this only needs to give it a reasonable initial spin at launch.
	var radius:float
	if ball_type.collision_shape:
		radius = ball_type.approx_radius * ball_shape.scale.x
	else:
		radius = (ball_shape.shape as SphereShape3D).radius * ball_shape.scale.x
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
