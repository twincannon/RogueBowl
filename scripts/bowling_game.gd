extends Node

enum PinType { NORMAL, TNT, FIREWORKS }

const TARGET_SCORE := 150
const MAX_FRAME := 10
const LAST_FRAME := MAX_FRAME - 1

# One ball thrown - everything needed to score it and draw it on a scorecard.
class BallThrow extends RefCounted:
	var pins_down := 0        # pins knocked down by this ball
	var rack_size := 10       # pins racked for this ball's rack lineage
	var standing_before := 10 # pins standing when this ball was thrown
	var fresh_rack := true    # thrown at a freshly set rack (vs. leftover pins)
	var strike_credits := 0   # rack_size/10 if this ball was a strike, else 0 - "every 10 pins in a throw is a strike"

	func cleared_rack() -> bool:
		return pins_down == standing_before

	func is_strike() -> bool:
		return fresh_rack and cleared_rack()

	func is_spare() -> bool:
		return not fresh_rack and cleared_rack()

# frames[frame_index][ball_index] -> BallThrow. Always MAX_FRAME entries, each an
# Array[BallThrow] holding the balls thrown so far in that frame (0-2, or 0-3 in the last frame).
var frames: Array[Array] = []

var current_frame := 0  # 0-based index into frames; == MAX_FRAME once the game is over
var current_ball := 0   # 0-based index into frames[current_frame]
var game_over := false
var final_result_win := false
var displayed_score := 0  # calculate_total_score(), refreshed after every throw

# Per-rack-lineage state, reset whenever a fresh rack is set up.
var current_rack_rows := 4  # SaveGame.pin_rows as of this rack lineage's start - locked in until the next fresh rack
var current_rack_size := 10
var rack_pin_types: Array[PinType] = []   # sized to current_rack_size, fixed for the rack's lifetime
var standing_positions: Array[bool] = []  # sized to current_rack_size, true = pin still present there

func _ready() -> void:
	_init_frames()

func _init_frames() -> void:
	frames = []
	for f in MAX_FRAME:
		var throws: Array[BallThrow] = []
		frames.append(throws)

func get_throw(frame: int, ball: int) -> BallThrow:
	var throws: Array = frames[frame]
	return throws[ball] if ball < throws.size() else null

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
	if current_ball == 0:
		return true
	# Mid-frame, only the last frame can re-rack: after a strike or spare its bonus ball gets fresh pins.
	return get_throw(current_frame, current_ball - 1).cleared_rack()

func record_throw(pins_down: int, standing_after: Array[bool]) -> void:
	var ball := BallThrow.new()
	ball.pins_down = pins_down
	ball.rack_size = current_rack_size
	ball.standing_before = standing_positions.count(true)
	ball.fresh_rack = needs_fresh_rack()
	if ball.is_strike():
		ball.strike_credits = current_rack_size / 10  # integer division
	frames[current_frame].append(ball)
	standing_positions = standing_after

	if _is_frame_complete(current_frame):
		current_frame += 1
		current_ball = 0
	else:
		current_ball += 1

	displayed_score = calculate_total_score()
	if current_frame >= MAX_FRAME:
		game_over = true
		final_result_win = displayed_score >= TARGET_SCORE

func _is_frame_complete(frame: int) -> bool:
	var throws: Array = frames[frame]
	if throws.is_empty():
		return false
	var first: BallThrow = throws[0]
	if frame < LAST_FRAME:
		return first.is_strike() or throws.size() >= 2
	# Last frame: a strike or spare earns a third ball; an open frame ends after two.
	if throws.size() >= 3:
		return true
	if throws.size() == 2:
		var second: BallThrow = throws[1]
		return not first.is_strike() and not second.is_spare()
	return false

# Sum of the next `count` balls thrown after frames[frame][after_ball], continuing into
# later frames as needed. -1 if those balls haven't all been thrown yet.
func _bonus_pins(frame: int, after_ball: int, count: int) -> int:
	var total := 0
	var found := 0
	var ball := after_ball + 1
	while frame < MAX_FRAME and found < count:
		var throws: Array = frames[frame]
		if ball < throws.size():
			total += (throws[ball] as BallThrow).pins_down
			found += 1
			ball += 1
		else:
			frame += 1
			ball = 0
	return total if found == count else -1

# Score earned by a single frame, or -1 if it can't be scored yet (unthrown, or waiting on bonus balls).
func get_frame_score(frame: int) -> int:
	var throws: Array = frames[frame]
	if throws.is_empty():
		return -1
	var first: BallThrow = throws[0]
	if first.is_strike():
		var bonus := _bonus_pins(frame, 0, 2)
		return -1 if bonus < 0 else first.strike_credits * (10 + bonus)
	if throws.size() >= 2 and (throws[1] as BallThrow).is_spare():
		var bonus := _bonus_pins(frame, 1, 1)
		return -1 if bonus < 0 else 10 + bonus
	if not _is_frame_complete(frame):
		return -1
	var total := 0
	for ball: BallThrow in throws:
		total += ball.pins_down
	return total

# Cumulative score through `frame` (a scorecard's running total), or -1 if any frame up to it is still pending.
func get_running_total(frame: int) -> int:
	var total := 0
	for f in frame + 1:
		var score := get_frame_score(f)
		if score < 0:
			return -1
		total += score
	return total

func calculate_total_score() -> int:
	var total := 0
	for f in MAX_FRAME:
		var score := get_frame_score(f)
		if score < 0:
			break  # pending - later frames can't be totalled yet either
		total += score
	return total

func reset_game() -> void:
	_init_frames()
	current_frame = 0
	current_ball = 0
	game_over = false
	final_result_win = false
	displayed_score = 0
	# Deliberately does NOT touch SaveGame.pins/hand/draw_pile/discard_pile/pin_rows - those persist across runs.
