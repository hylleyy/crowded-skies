extends CanvasLayer
class_name UI

#prefabs
var ace_prefab : PackedScene = preload('res://scenes/prefabs/ui_ace.tscn')

#dependencies
@onready var game_screen : Control = $GameScreen
@onready var menu_screen : Control = $MenuScreen
@onready var death_screen : Control = $DeathScreen

@onready var score_label : Label = $GameScreen/Score
@onready var aces_hblist : HBoxContainer = $GameScreen/Aces/HBoxContainer
@onready var respawn_countdown : Label = $DeathScreen/CenterContainer/VBoxContainer/Countdown


func refresh_game_screen_values(score : int, aces : int) -> void:
	update_score_ui(score)
	update_aces_ui(aces)

func update_score_ui(score : int) -> void:
	score_label.text = '%03d' % score

func update_aces_ui(aces_left : int) -> void:
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

func update_respawn_countdow(time_left : int) -> void:
	respawn_countdown.text = '%02d' % time_left
	if time_left == 0: show_menu_ui()

func show_game_ui() -> void:
	death_screen.hide()
	menu_screen.hide()
	game_screen.show()

func show_menu_ui() -> void:
	death_screen.hide()
	game_screen.hide()
	menu_screen.show()

func show_death_ui () -> void:
	game_screen.hide()
	death_screen.hide()
	death_screen.show()