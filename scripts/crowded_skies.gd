extends Node2D

@export var player : Player
@export var camera : Camera
@export var ui : UI
@export var pipes_distance : int = 600

@export var pipes_ahead : int = 5
@export var pipes_behind : int = 5

var pipes_prefab : PackedScene = preload('res://scenes/prefabs/pipes.tscn')
var _seed : int
var spawned_pipes : Dictionary = {}

@onready var pipes_group : Node2D = $PipesGroup

func _ready() -> void:
	var date : Dictionary = Time.get_datetime_dict_from_system()
	_seed = (date.year * 10000) + (date.month * 100) + date.day

	player.score_changed.connect(ui.update_score_ui)
	player.damaged.connect(ui.update_aces_ui)
	player.died.connect(_on_player_die)
	player.respawned.connect(ui.show_game_ui)
	player.respawn_countdown.connect(ui.update_respawn_countdow)

	ui.refresh_game_screen_values(player.score, player.aces)
	player.disable()

func _process(_delta: float) -> void:
	if not is_instance_valid(player): return
	manage_pipes()

func manage_pipes() -> void:
	var current_index : int = floor(camera.position.x / float(pipes_distance))

	var active_indices : Array = []
	for i in range(current_index - pipes_behind, current_index + pipes_ahead + 1):
		if i > 0: active_indices.append(i)

	for index in spawned_pipes.keys():
		if not index in active_indices:
			spawned_pipes[index].hide()
			# Note: If memory becomes an issue later, queue_free() here 
			# and erase the key from the dictionary instead of hiding.

	for index in active_indices:
		if spawned_pipes.has(index): spawned_pipes[index].show()
		else: _spawn_pipe(index)

func _spawn_pipe(index: int) -> void:
	var new_pipe = pipes_prefab.instantiate() as Pipes
	pipes_group.add_child(new_pipe)

	new_pipe.position.x = index * pipes_distance

	var index_rng = RandomNumberGenerator.new()
	index_rng.seed = _seed + index # unique, repeatable seed for thid specific pipe
	
	new_pipe.position.y = 0
	new_pipe.height = index_rng.randi_range(-300, 300)
	new_pipe.gap = index_rng.randi_range(220, 300)

	spawned_pipes[index] = new_pipe

func _on_player_die() -> void:
	ui.show_death_ui()

func _input(event: InputEvent) -> void: 
	if Network.rendering: return
	if not player.can_spawn: return
	if not event.is_action_pressed('Jump', true): return

	ui.refresh_game_screen_values(player.score, player.aces)
	ui.show_game_ui()
	player.spawn()
