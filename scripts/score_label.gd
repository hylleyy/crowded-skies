extends Label

@export var player : Player

func _ready() -> void: player.score_changed.connect(update_label)

func update_label(score : int) -> void: text = '%03d' % score