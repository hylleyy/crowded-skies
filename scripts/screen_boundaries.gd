extends StaticBody2D

func _ready() -> void:
	await get_tree().process_frame
	_build_screen_boundaries()

	get_tree().root.size_changed.connect(_build_screen_boundaries)

func _build_screen_boundaries() -> void:
	for child in get_children():
		child.queue_free()

	var view_size = get_viewport_rect().size
	
	var left   = -view_size.x / 2
	var right  =  view_size.x / 2
	var top    = -view_size.y / 2
	var bottom =  view_size.y / 2

	var walls = {
		'Top': [Vector2(left, top), Vector2(right, top)],
		'Bottom': [Vector2(left, bottom), Vector2(right, bottom)],
		'Left': [Vector2(left, top), Vector2(left, bottom)],
		'Right': [Vector2(right, top), Vector2(right, bottom)]
	}

	for wall_name in walls:
		var line = walls[wall_name]
		var collision_shape = CollisionShape2D.new()
		var segment = SegmentShape2D.new()

		segment.a = line[0]
		segment.b = line[1]

		collision_shape.shape = segment
		collision_shape.name = wall_name + "Wall"

		add_child(collision_shape)
