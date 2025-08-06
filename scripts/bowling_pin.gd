extends RigidBody3D
class_name BowlingPin

var pin_is_fallen := false


func _physics_process(delta: float) -> void:
	if !pin_is_fallen and _is_pin_fallen():
		pin_is_fallen = true
		SaveGame.pins += 1
	
	if position.y <= -10:
		set_freeze_enabled(true)
	
	if pin_is_fallen and Global.has_object_stopped_moving(self):
		set_freeze_enabled(true)

func is_pin_moving():
	return pin_is_fallen and !is_freeze_enabled()

func _is_pin_fallen() -> bool:
	var up_vector = Vector3.UP
	var pin_up = global_transform.basis.y
	var dot = up_vector.dot(pin_up)

	if dot < cos(deg_to_rad(70)):
		return true
	return false
