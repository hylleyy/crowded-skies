#	Copyright 2026 Inkpunk Game Studio
#
#	Licensed under the Apache License, Version 2.0 (the "License");
#	you may not use this file except in compliance with the License.
#	You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
#	Unless required by applicable law or agreed to in writing, software
#	distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#	See the License for the specific language governing permissions and
#	limitations under the License.

@tool
@icon('res://assets/artwork/icons/editor_pipes.svg')
extends Node2D
class_name Pipes

## The vertical offset adjustment applied to the entire pipe pair.
@export var height : float = 0.0:
	set(value):
		height = value
		if is_inside_tree() and has_node('Top') and has_node('Bottom'):
			#cite: 16
			_update_positions()

## The gap clearance distance separating the top and bottom pipes.
@export var gap : float = 300.0:
	set(value):
		gap = value
		if is_inside_tree() and has_node('Top') and has_node('Bottom'):
			_update_positions()

# dependencies
@onready var top : StaticBody2D = $Top as StaticBody2D
@onready var bottom : StaticBody2D = $Bottom as StaticBody2D
@onready var trigger_area : Area2D = $Area2D as Area2D
@onready var trigger_shape : CollisionShape2D = $Area2D/CollisionShape2D as CollisionShape2D
var conquered : bool = false

func _ready() -> void:
	if not Engine.is_editor_hint(): trigger_area.body_entered.connect(_on_trigger_body_entered)
	_update_positions()

func _update_positions() -> void:
	# fallback initialization handles tool-mode setter updates before _ready runs
	if not top or not bottom or not trigger_area or not trigger_shape:
		top = $Top as StaticBody2D
		bottom = $Bottom as StaticBody2D
		trigger_area = $Area2D as Area2D
		trigger_shape = $Area2D/CollisionShape2D as CollisionShape2D

	var half_gap : float = gap / 2.0

	top.position.y = -half_gap + height
	bottom.position.y = half_gap + height

	# safe cast to ensure standard autocompletion and safety for segment properties
	var segment_shape := trigger_shape.shape as SegmentShape2D
	if segment_shape:
		segment_shape.a = Vector2(0.0, -half_gap + height)
		segment_shape.b = Vector2(0.0, half_gap + height)

func _on_trigger_body_entered(body : Node2D) -> void:
	if conquered: return
	conquered = true
	var player := body as Player
	if player: player.increase_score(1)