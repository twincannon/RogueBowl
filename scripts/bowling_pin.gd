extends RigidBody3D
class_name BowlingPin

var pin_is_fallen := false
var _freeze_eligible_at_msec := 0

func _ready() -> void:
	add_to_group("pins")

## Suppress the stopped-moving freeze check for the next `seconds` - use this
## after giving a pin a strong impulse (e.g. an explosion) so it doesn't get
## frozen mid-flight the instant its velocity passes through zero (which
## happens for real, not just as a stale reading, at the apex of a toss).
func delay_freeze(seconds: float) -> void:
	_freeze_eligible_at_msec = max(_freeze_eligible_at_msec, Time.get_ticks_msec() + int(seconds * 1000.0))

func _physics_process(delta: float) -> void:
	if !pin_is_fallen and _is_pin_fallen():
		pin_is_fallen = true
		SaveGame.pins += 1

	if position.y <= -10:
		set_freeze_enabled(true)

	if pin_is_fallen and Time.get_ticks_msec() >= _freeze_eligible_at_msec and Global.has_object_stopped_moving(self):
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
