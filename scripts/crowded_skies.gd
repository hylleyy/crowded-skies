extends Node2D

@export var player : Player
@export var ui : UI

func _ready() -> void:
	player.score_changed.connect(ui.update_score_ui)
	player.damaged.connect(ui.update_aces_ui)
	player.died.connect(_on_player_die)
	player.respawned.connect(ui.show_game_ui)
	player.respawn_countdown.connect(ui.update_respawn_countdow)

	ui.refresh_game_screen_values(player.score, player.aces)
	player.disable()

func _on_player_die() -> void:
	# player.disable()
	ui.show_death_ui()
	return

func _input(event: InputEvent) -> void: # And I'm pretty sure this is overkill
	if Network.rendering: return
	if not player.can_spawn: return
	if not event is InputEventMouseButton: return
	if not event.pressed: return
	if event.button_index != MOUSE_BUTTON_LEFT: return

	ui.refresh_game_screen_values(player.score, player.aces)
	ui.show_game_ui()
	player.spawn()
