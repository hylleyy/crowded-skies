extends CanvasLayer

@export var player : Player

#prefabs
var ace_prefab : PackedScene = preload('res://scenes/prefabs/ui_ace.tscn')

#dependencies
@onready var score_label : Label = $Score
@onready var aces_hblist : HBoxContainer = $Aces/HBoxContainer

func _ready() -> void:
	player.score_changed.connect(_update_score_ui)
	player.damaged.connect(_update_aces_ui)

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
