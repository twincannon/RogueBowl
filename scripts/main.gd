extends Node3D

var bowling_pin_scene = preload("res://scenes/bowling_pin.tscn")
var pins:Array[BowlingPin]

func _ready() -> void:
	
	%Ball/BallShape.scale = Vector3(SaveGame.ball_scale,SaveGame.ball_scale,SaveGame.ball_scale)
	%Ball/BallMesh.scale = Vector3(SaveGame.ball_scale,SaveGame.ball_scale,SaveGame.ball_scale)
	
	var positions = generate_bowling_pin_positions(0.3048)
	for pos in positions:
		var new_pin = bowling_pin_scene.instantiate()
		$BowlingPinRoot.add_child(new_pin)
		new_pin.global_position.x = $BowlingPinRoot.position.x + pos.x
		new_pin.global_position.z = $BowlingPinRoot.position.z + pos.y
		new_pin.global_position.y = $BowlingPinRoot.position.y
		pins.append(new_pin)

	#var row = 0
	#for i in range(0, 10):
		#if i == 1 or i == 3 or i == 6:
			#row += 1
		#var new_pin = bowling_pin_scene.instantiate()
		#$BowlingPinRoot.add_child(new_pin)
		#new_pin.position.x = row * 1
		#if row <= 1:
			#new_pin.position.z = i * 0.75 - row * 1.1
		#elif row == 2:
			#new_pin.position.z = i * 0.75 - row * (1.1 + 1.1 - 0.75)
		#else:
			#new_pin.position.z = i * 0.75 - row * (1.1 + 1.1 + 0.55 - 0.75)
		#pass

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
			if pin.is_pin_moving():
				any_pin_moving = true
				break
	if %Ball.launched and !any_pin_moving and %Ball.is_freeze_enabled():
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _input(event):
	if event.is_action_pressed("launch") and not %Ball.launched:
		%Ball.launch(%PowerBar.value, %SpinBar.value)

		%PowerBar.paused = true
		get_tree().create_timer(10.0).timeout.connect(on_ball_timeout.bind())
		
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("cheat_addpins"):
		SaveGame.pins += 1000

func on_ball_timeout():
	%Ball.set_freeze_enabled(true)

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")
