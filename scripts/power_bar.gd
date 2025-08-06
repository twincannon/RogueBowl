extends ProgressBar

var speed := 50.0  # how fast it fills/unfills (percentage per second)
var direction := 1  # 1 = increasing, -1 = decreasing
var paused := false

func _process(delta):
	if paused: return
	
	value += direction * speed * delta
	
	if value >= max_value:
		value = max_value
		direction = -1  # reverse
	elif value <= min_value:
		value = min_value
		direction = 1  # reverse again
