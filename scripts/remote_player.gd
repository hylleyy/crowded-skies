#	Copyright 2026 INKPNK Game Studio
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

extends CharacterBody2D
class_name RemotePlayer

@export var label_y_offset : float
@export var label_lerp_weight : float = .5
@export var jump_delay_reference : float = .1
@export var feathers_textures : Array[Texture2D]
var last_checked : float

var nickname : String
var id : String

var target_position : Vector2 = Vector2.ZERO

@onready var label : Label = $Label
@onready var sprite : Sprite2D = $Sprite2D
@onready var collision : CollisionPolygon2D = $CollisionPolygon2D
@onready var tails_container : Node2D = $Tail
@onready var wings_container : Node2D = $Wings 
@onready var wings_animator : AnimationPlayer = $Wings/AnimationPlayer
@onready var wosh_sound : AudioStreamPlayer2D = $Sounds/Wosh

var rendering : bool = true:
	set(value):
		rendering = value
		if rendering:
			show()
			if collision: collision.disabled = false
		else:
			hide()
			if collision: collision.disabled = true
			if tails_container: for child in tails_container.get_children():
				child.hide()
				child.queue_free()


func _ready() -> void:
	if not rendering: collision.disabled = true
	wings_animator.animation_finished.connect(func(animation_name: String) : if animation_name != 'RESET': wings_animator.play('RESET'))
	label.text = nickname

func _process(_delta: float) -> void:
	if not rendering: return

	label.position = Vector2(position.x - label.size.x/2, position.y + label_y_offset) # label.position.lerp(Vector2(position.x - label.size.x/2, position.y + label_y_offset), label_lerp_weight)

func _physics_process(delta: float) -> void:
	if not rendering: return

	var to_target = target_position - position

	if to_target.length() > 2.:
		velocity = to_target * 15.
	else:
		velocity = Vector2.ZERO
		position = target_position

	move_and_slide()
	_handle_direction_and_rotation(delta)

	if _player_probably_jumped():
		_generate_feathers(velocity.x)
		wosh_sound.play()
		if wings_animator.current_animation.get_basename() != 'flap': wings_animator.play('flap')

		return

func set_nickname(new_nickname : String) -> void:
	nickname = new_nickname

func _handle_direction_and_rotation(delta: float) -> void:
	if velocity.x != 0: sprite.flip_h = velocity.x < 0

	var direction_sign: float = -1. if sprite.flip_h else 1.
	wings_container.position.x = abs(wings_container.position.x) * direction_sign * -1

	if velocity.y < 0:
		var target_up = deg_to_rad(-30.0) * direction_sign
		rotation = lerp(rotation, target_up, 20.0 * delta)
	else:
		var target_down = deg_to_rad(90.0) * direction_sign
		rotation = lerp(rotation, target_down, 4.0 * delta)

func _player_probably_jumped() -> bool:
	if velocity.y >= -(Player.static_jump_force*1.1): return false
	if Time.get_unix_time_from_system() - last_checked <= jump_delay_reference: return false
	last_checked = Time.get_unix_time_from_system()
	return true

func _generate_feathers(direction : float) -> void:
	@warning_ignore("integer_division")
	var _maximum_feathers : int = Player.MAXIMUM_FEATHERS / feathers_textures.size()
	if _maximum_feathers <= 0: return

	for texture in feathers_textures:
		var particles = CPUParticles2D.new()

		particles.texture = texture
		particles.one_shot = true
		particles.explosiveness = 1.
		particles.lifetime = 4.
		particles.amount = _maximum_feathers
		particles.scale_amount_min = sprite.scale.x
		particles.scale_amount_max = sprite.scale.x
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 50.
		particles.local_coords = false
		particles.direction = Vector2(sign(direction), -1)
		particles.spread = 45.
		particles.initial_velocity_min = 250.
		particles.initial_velocity_max = 350.
		particles.z_index = -999

		tails_container.add_child(particles)
		particles.finished.connect(particles.queue_free)
		particles.emitting = true
