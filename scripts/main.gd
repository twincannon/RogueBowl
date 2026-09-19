extends Node3D

var ball_scene = preload("res://scenes/ball.tscn")
var bowling_pin_scene = preload("res://scenes/bowling_pin.tscn")
var tnt_pin_scene = preload("res://scenes/tnt_pin.tscn")
var fireworks_pin_scene = preload("res://scenes/fireworks_pin.tscn")
var pins:Array[BowlingPin]
var balls_in_hand:Array[Ball]

const BASE_BALL_RADIUS := 0.1
const BASE_BALL_MASS := 7.26

var base_lane_y := 0.0  # %Ball's authored y position, captured before any selection scales it
var pin_rack_indices: Array[int] = []  # pins[i] came from rack position pin_rack_indices[i]
var _throw_recorded := false

func _ready() -> void:
	
	SaveGame.ball_upgraded.connect(on_ball_upgraded)
	
	set_camera($BallReturnCamera, false)
	
	# Show balls in ball return (players hand)
	for i in SaveGame.hand.size():
		var current_ball = SaveGame.hand[i] as PlayerBall
		if is_instance_valid(current_ball):
			var new_scene = ball_scene.instantiate() as Ball
			new_scene.position.x =  i * 0.4
			new_scene.is_active_ball = false
			new_scene.ball_type = current_ball.ball_type
			new_scene.on_ball_selected.connect(ball_selected.bind(i))
			balls_in_hand.append(new_scene)
			
			var ball: PlayerBall = SaveGame.hand[i]
			new_scene.update_text_stats(ball)
			
			$BallReturnRoot.add_child(new_scene)
		

	base_lane_y = %Ball.position.y - BASE_BALL_RADIUS

	if BowlingGame.game_over:
		%Ball.visible = false
		return  # no pins, no ball selection - the result UI takes over (see _process)

	# No ball is in the lane until the player picks one up from the ball
	# return - reset any stale selection from a previous scene instance.
	# Connect before resetting (not just setting the var directly) so the
	# slot buttons - already connected from their own earlier _ready(),
	# since children ready before their parent - actually hear about it and
	# re-enable themselves instead of staying stuck disabled.
	SaveGame.select_ball(-1)

	if BowlingGame.needs_fresh_rack():
		BowlingGame.start_fresh_rack()

	var positions = generate_bowling_pin_positions(0.3048, BowlingGame.current_rack_rows)
	for i in positions.size():
		if not BowlingGame.standing_positions[i]:
			continue  # already knocked down earlier in this rack lineage - stays empty
		var new_pin = _instantiate_pin(BowlingGame.rack_pin_types[i])
		$BowlingPinRoot.add_child(new_pin)
		new_pin.global_position.x = $BowlingPinRoot.position.x + positions[i].x
		new_pin.global_position.z = $BowlingPinRoot.position.z + positions[i].y
		new_pin.global_position.y = $BowlingPinRoot.position.y
		pins.append(new_pin)
		pin_rack_indices.append(i)
		
func on_ball_upgraded(ball_index:int):
	if ball_index in range(balls_in_hand.size()):
		balls_in_hand[ball_index].update_text_stats(SaveGame.hand[ball_index])
		update_ball_stats(ball_index)
		
func ball_selected(ball_index:int):
	set_camera($LaneCamera, true)
	
	update_ball_stats(ball_index)
	
	%BackButton.visible = true
	
	SaveGame.selected_hand_index = ball_index
	%Ball.visible = true

func update_ball_stats(ball_index:int):
	var selected_ball: PlayerBall = SaveGame.hand[ball_index]
	%Ball.ball_type = selected_ball.ball_type
	%Ball.vel_scale_multiplier = selected_ball.ball_vel_scale
	var bt := selected_ball.ball_type
	var combined_scale:float = selected_ball.ball_scale * bt.scale_multiplier
	var vecscale := Vector3(combined_scale,combined_scale,combined_scale)
	%Ball/BallShape.scale = vecscale
	%Ball/BallMesh.scale = vecscale
	if %Ball.visual_instance:
		%Ball.visual_instance.scale = vecscale
	var resting_radius:float = bt.approx_radius if bt.collision_shape else BASE_BALL_RADIUS
	%Ball.position.y = base_lane_y + resting_radius * combined_scale
	%Ball.set_mass(BASE_BALL_MASS * pow(combined_scale, 3.0) * bt.mass_multiplier)


func set_camera(camera:Camera3D, lerp_camera:bool):
	if lerp_camera:
		var tween = create_tween().set_parallel(true)
		tween.tween_property($GameCamera, "position", camera.position, 1.0)
		tween.tween_property($GameCamera, "rotation", camera.rotation, 1.0)
		tween.tween_property($GameCamera, "fov", camera.fov, 1.0)
	else:
		$GameCamera.position = camera.position
		$GameCamera.rotation = camera.rotation
		$GameCamera.fov = camera.fov

func _instantiate_pin(type: BowlingGame.PinType) -> BowlingPin:
	match type:
		BowlingGame.PinType.TNT: return tnt_pin_scene.instantiate() as BowlingPin
		BowlingGame.PinType.FIREWORKS: return fireworks_pin_scene.instantiate() as BowlingPin
		_: return bowling_pin_scene.instantiate() as BowlingPin

func generate_bowling_pin_positions(pin_spacing: float, row_count: int) -> Array[Vector2]:
	var positions:Array[Vector2] = []

	# Equilateral triangle layout (4 rows, 10 pins total)
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
		$GameCamera.fov = lerpf($GameCamera.fov, 10.0, 2.0 * delta)
		$GameCamera.position.y = lerpf($GameCamera.position.y, 1.5, 2.0 * delta)

	%PinsLabel.text = "Pins: " + str(SaveGame.pins)
	%ScoreLabel.text = "Score: %d / %d" % [BowlingGame.displayed_score, BowlingGame.TARGET_SCORE]

	%FrameLabel.visible = not BowlingGame.game_over
	%FrameLabel.text = "Frame %d, Ball %d" % [BowlingGame.current_frame, BowlingGame.current_ball_in_frame]

	%ResultLabel.visible = BowlingGame.game_over
	if BowlingGame.game_over:
		var headline := "YOU WIN!" if BowlingGame.final_result_win else "Game Over."
		%ResultLabel.text = "%s Score: %d / %d" % [headline, BowlingGame.displayed_score, BowlingGame.TARGET_SCORE]

	%NewGameButton.visible = BowlingGame.game_over
	%SkipButton.visible = !BowlingGame.game_over and %Ball.launched

func _physics_process(delta: float) -> void:
	if BowlingGame.game_over:
		return

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
		_end_current_ball()

func _end_current_ball():
	if not _throw_recorded:
		_throw_recorded = true
		_record_throw_result()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _record_throw_result() -> void:
	var pins_down := 0
	var standing_after := BowlingGame.standing_positions.duplicate()
	for i in pins.size():
		var rack_idx := pin_rack_indices[i]
		# A freed pin (a FireworksPin queue_free()s itself ~1.6s after ignition,
		# without ever calling set_freeze_enabled - see fireworks_pin.gd) must
		# still count as fallen, or it's silently miscounted as still standing.
		if not is_instance_valid(pins[i]) or pins[i].pin_is_fallen:
			pins_down += 1
			standing_after[rack_idx] = false
	BowlingGame.record_throw(pins_down, standing_after)

func _input(event):
	if event.is_action_pressed("launch") and not %Ball.launched and SaveGame.selected_hand_index != -1 and not BowlingGame.game_over:
		%Ball.launch(%PowerBar.value, %SpinBar.value)
		SaveGame.throw_ball(SaveGame.selected_hand_index)
		%BackButton.visible = false

		%PowerBar.paused = true
		get_tree().create_timer(10.0).timeout.connect(on_ball_timeout.bind())
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cheat_addpins"):
		SaveGame.pins += 1000

func on_ball_timeout():
	%Ball.set_freeze_enabled(true)

func _on_button_pressed() -> void:
	_end_current_ball()


func _on_back_button_pressed() -> void:
	set_camera($BallReturnCamera, true)
	%BackButton.visible = false


func _on_new_game_button_pressed() -> void:
	if BowlingGame.game_over:
		BowlingGame.reset_game()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
