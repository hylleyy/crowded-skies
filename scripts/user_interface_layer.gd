extends CanvasLayer

@export var player : Player

#prefabs
var ace_prefab : PackedScene = preload('res://scenes/prefabs/ui_ace.tscn')

#dependencies
@onready var game_screen : Control = $GameScreen
@onready var menu_screen : Control = $MenuScreen
@onready var death_screen : Control = $DeathScreen

@onready var score_label : Label = $GameScreen/Score
@onready var aces_hblist : HBoxContainer = $GameScreen/Aces/HBoxContainer
@onready var respawn_countdown : Label = $DeathScreen/CenterContainer/VBoxContainer/Countdown

func _ready() -> void:
	player.score_changed.connect(_update_score_ui)
	player.damaged.connect(_update_aces_ui)
	player.died.connect(_on_player_die)
	player.respawned.connect(_on_player_repawn)
	player.respawn_countdown.connect(func(time_left : int): respawn_countdown.text = '%02d' % time_left)

func _refresh_game_screen_values() -> void:
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

func _on_player_die() -> void:
	player.disable()
	game_screen.hide()
	death_screen.show()
	_refresh_game_screen_values()

func _on_player_repawn() -> void:
	death_screen.hide()
	death_screen.hide()
	menu_screen.show()

func _input(event: InputEvent) -> void: # And I'm pretty sure this is overkill
	if not menu_screen.visible: return
	if not event is InputEventMouseButton: return
	if not event.pressed: return
	if event.button_index != MOUSE_BUTTON_LEFT: return

	menu_screen.hide()
	death_screen.hide()
	_refresh_game_screen_values()
	game_screen.show()
	player.enable() # This also shouldn't be here
	Network.set_render(true) # This shouldn't be here
