extends Node

enum PinType { NORMAL, TNT, FIREWORKS }

const TARGET_SCORE := 150
const MAX_FRAME := 10

var current_frame := 1          # 1-10
var current_ball_in_frame := 1  # 1, 2, or (frame 10 only) 3
var game_over := false
var final_result_win := false
var displayed_score := 0        # calculate_total_score(), refreshed after every throw

# Flat, in-order, one entry per ball thrown this game - the sole scoring input.
var ball_pins: Array[int] = []           # raw pins knocked down
var ball_rack_size: Array[int] = []      # how many pins were racked for the frame this ball belongs to
var ball_strike_credits: Array[int] = [] # rack_size/10 if this ball cleared the WHOLE rack, else 0

# Per-rack-lineage state, reset whenever a fresh rack is set up.
var current_rack_rows := 4  # SaveGame.pin_rows as of this rack lineage's start - locked in until the next fresh rack
var current_rack_size := 10
var rack_pin_types: Array[PinType] = []   # sized to current_rack_size, fixed for the rack's lifetime
var standing_positions: Array[bool] = []  # sized to current_rack_size, true = pin still present there

# Frame 10 bookkeeping
var frame10_ball1_was_strike := false
var frame10_ball2_was_strike := false
var frame10_ball3_fresh_rack := false

func roll_pin_type() -> PinType:
	var roll := randf()
	if roll < SaveGame.tnt_pin_chance:
		return PinType.TNT
	elif roll < SaveGame.tnt_pin_chance + SaveGame.firework_pin_chance:
		return PinType.FIREWORKS
	return PinType.NORMAL

func start_fresh_rack() -> void:
	# Locked in for the whole rack lineage (ball 1 through its ball 2/3), so a
	# Pin Count purchase mid-frame can't desync the continuation ball's layout
	# from what standing_positions/rack_pin_types were sized for.
	current_rack_rows = SaveGame.pin_rows
	current_rack_size = current_rack_rows * (current_rack_rows + 1) / 2
	rack_pin_types = []
	standing_positions = []
	for i in current_rack_size:
		rack_pin_types.append(roll_pin_type())
		standing_positions.append(true)

func needs_fresh_rack() -> bool:
	if current_frame < MAX_FRAME:
		return current_ball_in_frame == 1
	match current_ball_in_frame:
		1: return true
		2: return frame10_ball1_was_strike
		3: return frame10_ball3_fresh_rack
	return false

func record_throw(pins_down: int, standing_after: Array[bool]) -> void:
	ball_pins.append(pins_down)
	ball_rack_size.append(current_rack_size)
	var credits := 0
	if pins_down == current_rack_size:
		credits = current_rack_size / 10  # "every 10 pins in a throw is a strike" - integer division
	ball_strike_credits.append(credits)
	standing_positions = standing_after

	if current_frame < MAX_FRAME:
		_advance_frames_1_to_9(pins_down)
	else:
		_advance_frame_10(pins_down)

	displayed_score = calculate_total_score()
	if current_frame > MAX_FRAME:
		game_over = true
		final_result_win = displayed_score >= TARGET_SCORE

func _advance_frames_1_to_9(pins_down: int) -> void:
	if current_ball_in_frame == 1:
		if pins_down == current_rack_size:   # full clear - frame ends immediately
			current_frame += 1
			current_ball_in_frame = 1
		else:
			current_ball_in_frame = 2         # ball 2 continues from standing pins
	else:
		current_frame += 1                   # frame always ends after ball 2
		current_ball_in_frame = 1

func _advance_frame_10(pins_down: int) -> void:
	match current_ball_in_frame:
		1:
			frame10_ball1_was_strike = (pins_down == current_rack_size)
			current_ball_in_frame = 2
		2:
			frame10_ball2_was_strike = (pins_down == current_rack_size)
			var b1: int = ball_pins[ball_pins.size() - 2]
			var b1_rack: int = ball_rack_size[ball_rack_size.size() - 2]
			var b2: int = pins_down
			if frame10_ball1_was_strike and frame10_ball2_was_strike:
				frame10_ball3_fresh_rack = true      # strike-strike: fresh bonus rack
				current_ball_in_frame = 3
			elif frame10_ball1_was_strike:
				frame10_ball3_fresh_rack = false      # strike-open: ball 3 continues ball 2's standing pins
				current_ball_in_frame = 3
			elif b1 + b2 == b1_rack:                  # spare (cleared ball 1's rack across both balls)
				frame10_ball3_fresh_rack = true
				current_ball_in_frame = 3
			else:
				current_frame = MAX_FRAME + 1         # open, no bonus - game over, no ball 3
		3:
			current_frame = MAX_FRAME + 1             # ball 3 is always the game's last ball

func calculate_total_score() -> int:
	var total := 0
	var i := 0
	while i < ball_pins.size():
		if ball_strike_credits[i] > 0:
			if i + 2 >= ball_pins.size():
				break  # bonus balls not thrown yet - pending, stop here
			total += ball_strike_credits[i] * (10 + ball_pins[i + 1] + ball_pins[i + 2])
			i += 1
		elif i + 1 < ball_pins.size() and ball_pins[i] + ball_pins[i + 1] == ball_rack_size[i]:  # spare
			if i + 2 >= ball_pins.size():
				break
			total += 10 + ball_pins[i + 2]
			i += 2
		else:  # open frame
			if i + 1 >= ball_pins.size():
				break
			total += ball_pins[i] + ball_pins[i + 1]
			i += 2
	return total

func reset_game() -> void:
	current_frame = 1
	current_ball_in_frame = 1
	ball_pins = []
	ball_rack_size = []
	ball_strike_credits = []
	game_over = false
	final_result_win = false
	displayed_score = 0
	frame10_ball1_was_strike = false
	frame10_ball2_was_strike = false
	frame10_ball3_fresh_rack = false
	# Deliberately does NOT touch SaveGame.pins/hand/draw_pile/discard_pile/pin_rows - those persist across runs.
