extends CanvasLayer

@export var player : Player

#prefabs
var ace_prefab : PackedScene = preload('res://scenes/prefabs/ui_ace.tscn')

#dependencies
@onready var score_label : Label = $Score
@onready var aces_hblist : HBoxContainer = $Aces/HBoxContainer
@onready var game_over_screen : Control = $GameOver
@onready var respawn_countdown : Label = $GameOver/CenterContainer/VBoxContainer/Countdown
@onready var main_menu_group : Control = $MainMenu

func _ready() -> void:
	player.score_changed.connect(_update_score_ui)
	player.damaged.connect(_update_aces_ui)
	player.died.connect(_on_player_die)
	player.respawned.connect(_on_player_repawn)
	player.respawn_countdown.connect(_update_respawn_timer)

	_update_score_ui(player.score)
	_update_aces_ui(player.aces)

func _refresh_ui() -> void:
	_update_score_ui(player.score)
	_update_aces_ui(player.aces)

func _update_score_ui(score : int) -> void:
	score_label.text = '%03d' % score

func _update_aces_ui(aces_left : int) -> void:
	var existing_ui_child = aces_hblist.get_children()
	var existing_ui_count = existing_ui_child.size()

	for i in range(max(existing_ui_count, aces_left)):
		if i < aces_left and i < existing_ui_count: # CASE 1: we have an existing node to reuse
			var child = existing_ui_child[i]
			child.show()
			continue
		
		if i < aces_left and i >= existing_ui_count: # CASE 2: we need more ui objects than we have
			var new_ui_ace = ace_prefab.instantiate()
			aces_hblist.add_child(new_ui_ace)
			continue
		
		if i >= aces_left and i < existing_ui_count: # CASE 3: we need fewer items than we have
			var extra_child = existing_ui_child[i]
			extra_child.hide()

func _update_respawn_timer(time_left : int) -> void:
	respawn_countdown.text = '%02d' % time_left

func _on_player_die() -> void:
	game_over_screen.show()
	_refresh_ui()

func _on_player_repawn() -> void:
	game_over_screen.hide()
	_refresh_ui()

func _input(event: InputEvent) -> void:
	if not main_menu_group.visible: return
	if not event is InputEventMouseButton: return
	if not event.pressed: return
	if event.button_index != MOUSE_BUTTON_LEFT: return
	main_menu_group.hide()