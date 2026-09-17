extends Node

var pins := 0

# Upgrades
var pin_rows := 4

# Ball types
enum BallTypeId { DEFAULT, FIREBALL, BLACK_HOLE }

const BALL_TYPE_RESOURCES := {
	BallTypeId.DEFAULT: preload("res://resources/ball_types/default.tres"),
	BallTypeId.FIREBALL: preload("res://resources/ball_types/fireball.tres"),
	BallTypeId.BLACK_HOLE: preload("res://resources/ball_types/black_hole.tres"),
}

# Ball collection ("deck of cards"): hand is the 3 visible/selectable balls,
# draw_pile is the hidden shuffled reserve, discard_pile holds thrown balls
# until the draw pile runs dry and gets reshuffled.
signal ball_selected(hand_index: int)

var hand: Array[PlayerBall] = []
var draw_pile: Array[PlayerBall] = []
var discard_pile: Array[PlayerBall] = []
var selected_hand_index := -1  # -1 = no ball picked up from the return yet

func _ready() -> void:
	if hand.is_empty():
		for i in 3:
			hand.append(PlayerBall.new(BALL_TYPE_RESOURCES[BallTypeId.DEFAULT]))  # 3 starting Default balls

func select_ball(hand_index: int) -> void:
	selected_hand_index = hand_index
	ball_selected.emit(hand_index)

func add_ball_to_collection(type_id: BallTypeId) -> void:
	draw_pile.append(PlayerBall.new(BALL_TYPE_RESOURCES[type_id]))

func throw_ball(hand_index: int) -> PlayerBall:
	if hand_index < 0 or hand_index >= hand.size():
		return null
	var thrown := hand[hand_index]
	hand.remove_at(hand_index)
	discard_pile.append(thrown)

	if draw_pile.is_empty():
		draw_pile = discard_pile.duplicate()
		draw_pile.shuffle()
		discard_pile.clear()

	hand.insert(hand_index, draw_pile.pop_front())
	return thrown

# Pin types
var tnt_pin_chance := 0.1
var firework_pin_chance := 0.1
