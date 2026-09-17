extends Node3D

var bowling_pin_scene = preload("res://scenes/bowling_pin.tscn")
var tnt_pin_scene = preload("res://scenes/tnt_pin.tscn")
var fireworks_pin_scene = preload("res://scenes/fireworks_pin.tscn")
var pins:Array[BowlingPin]

const BASE_BALL_RADIUS := 0.1
const BASE_BALL_MASS := 7.26

var base_lane_y := 0.0  # %Ball's authored y position, captured before any selection scales it

func _ready() -> void:

	base_lane_y = %Ball.position.y - BASE_BALL_RADIUS

	# No ball is in the lane until the player picks one up from the ball
	# return - reset any stale selection from a previous scene instance.
	# Connect before resetting (not just setting the var directly) so the
	# slot buttons - already connected from their own earlier _ready(),
	# since children ready before their parent - actually hear about it and
	# re-enable themselves instead of staying stuck disabled.
	SaveGame.ball_selected.connect(_on_ball_selected)
	SaveGame.select_ball(-1)

	var positions = generate_bowling_pin_positions(0.3048)
	for pos in positions:
		var new_pin = _instantiate_pin()
		$BowlingPinRoot.add_child(new_pin)
		new_pin.global_position.x = $BowlingPinRoot.position.x + pos.x
		new_pin.global_position.z = $BowlingPinRoot.position.z + pos.y
		new_pin.global_position.y = $BowlingPinRoot.position.y
		pins.append(new_pin)

func _on_ball_selected(hand_index: int) -> void:
	if %Ball.launched:
		return

	if hand_index < 0:
		%Ball.visible = false
		return

	# Swap whichever ball was previously spawned for the newly picked one -
	# re-selecting a different ball before throwing is allowed.
	var selected_ball: PlayerBall = SaveGame.hand[hand_index]
	%Ball.ball_type = selected_ball.ball_type
	%Ball.vel_scale_multiplier = selected_ball.ball_vel_scale
	var bt := selected_ball.ball_type

	var combined_scale:float = selected_ball.ball_scale * bt.scale_multiplier
	%Ball/BallShape.scale = Vector3(combined_scale,combined_scale,combined_scale)
	%Ball/BallMesh.scale = Vector3(combined_scale,combined_scale,combined_scale)
	%Ball.position.y = base_lane_y + BASE_BALL_RADIUS * combined_scale
	%Ball.set_mass(BASE_BALL_MASS * pow(combined_scale, 3.0) * bt.mass_multiplier)

	%Ball.visible = true

func _instantiate_pin() -> BowlingPin:
	var roll := randf()
	if roll < SaveGame.tnt_pin_chance:
		return tnt_pin_scene.instantiate() as BowlingPin
	elif roll < SaveGame.tnt_pin_chance + SaveGame.firework_pin_chance:
		return fireworks_pin_scene.instantiate() as BowlingPin
	return bowling_pin_scene.instantiate() as BowlingPin

func generate_bowling_pin_positions(pin_spacing: float) -> Array[Vector2]:
	var positions:Array[Vector2] = []
	
	# Equilateral triangle layout (4 rows, 10 pins total)
	var row_count := SaveGame.pin_rows
	
	for row in range(row_count):
		var pins_in_row := row + 1
		var y := row * (pin_spacing * 0.866)  # sin(60°) = 0.866, for vertical offset
		var start_x := -((pins_in_row - 1) * pin_spacing / 2.0)
		
		for col in range(pins_in_row):
			var x := start_x + col * pin_spacing
			positions.append(Vector2(y, -x)) #y,-x instead of x,y to rotate 90 degrees
	
	return positions

func _process(delta: float) -> void:
	if %Ball.launched:
		$Camera3D.fov = lerpf($Camera3D.fov, 10.0, 2.0 * delta)
		$Camera3D.position.y = lerpf($Camera3D.position.y, 1.5, 2.0 * delta)
	
	%PinsLabel.text = "Pins: " + str(SaveGame.pins)

func _physics_process(delta: float) -> void:
	if !%Ball.launched:
		if Input.is_action_pressed("move_left"):
			var t = %Ball.get_transform()
			t.origin.z -= 1 * delta
			%Ball.set_transform(t)
		if Input.is_action_pressed("move_right"):
			var t = %Ball.get_transform()
			t.origin.z += 1 * delta
			%Ball.set_transform(t)
		
	if Input.is_action_pressed("spin_left"):
		%SpinBar.value -= 20 * delta
	if Input.is_action_pressed("spin_right"):
		%SpinBar.value += 20 * delta
		
	if Input.is_action_pressed("angle_left"):
		%AngleBar.value -= 20 * delta
	if Input.is_action_pressed("angle_right"):
		%AngleBar.value += 20 * delta
		
	%Ball.rotation_degrees.y = -%AngleBar.value
		
	if Global.has_object_stopped_moving(%Ball):
		%Ball.set_freeze_enabled(true)
	
	var any_pin_moving = false
	if %Ball.launched:
		for pin in pins:
			# A fireworks pin queue_free()s itself shortly after bursting.
			if is_instance_valid(pin) and pin.is_pin_moving():
				any_pin_moving = true
				break
	if %Ball.launched and !any_pin_moving and %Ball.is_freeze_enabled():
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _input(event):
	if event.is_action_pressed("launch") and not %Ball.launched and SaveGame.selected_hand_index != -1:
		%Ball.launch(%PowerBar.value, %SpinBar.value)
		SaveGame.throw_ball(SaveGame.selected_hand_index)

		%PowerBar.paused = true
		get_tree().create_timer(10.0).timeout.connect(on_ball_timeout.bind())
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cheat_addpins"):
		SaveGame.pins += 1000

func on_ball_timeout():
	%Ball.set_freeze_enabled(true)

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
