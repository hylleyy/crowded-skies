@tool
extends Node2D

@export var height : float = 0.:
	set(value):
		height = value
		if is_inside_tree() and has_node("Top") and has_node("Bottom"):
			update_positions()

@export var gap : float = 300.:
	set(value):
		gap = value
		if is_inside_tree() and has_node("Top") and has_node("Bottom"):
			update_positions()

var top : StaticBody2D
var bottom : StaticBody2D

func _ready() -> void:
	top = $Top
	bottom = $Bottom
	update_positions()

func update_positions() -> void:
	if not top or not bottom:
		top = $Top
		bottom = $Bottom
	top.position.y = (-(gap / 2)) + height
	bottom.position.y = (gap / 2) + height
