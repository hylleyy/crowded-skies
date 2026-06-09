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

extends CharacterBody2D
class_name Player

## Emitted when the player successfully executes a jump.
signal jump
## Emitted when the player enters the dead state.
signal died
## Emitted when the player enters the game again after dying.
signal respawned
## Emitted when the player takes damage.
signal damaged(aces_left : int)
## Emitted when colliding with another player instance.
signal remote_player_knockback
## Emitted when player score changes.
signal score_changed(score : int)
## Emitted when player dies and the internal respawn countdown begins counting
signal respawn_countdown(remaining : int)
## Emitted when the player exits the camera view.
signal exit_view
## Emitted when the player enters the camera view.
signal enter_view

@export_group('Experience')
## The amount of damage a player can take before dying. Change this to change the starter aces.
@export var aces : int = 3
var base_aces : int # We'll restore the player aces to this after dying
## The amount of score the player has to use along the game (works like the game currency). Change this to set the starter score.
@export var score : int = 0
## The time, in seconds, the player has to wait before respawning again.
@export var respawn_delay : int = 10

@export_group('Arcade Physics')
## The upward velocity applied on jump execution.
@export var jump_force : float = 800.
## The impulse force applied when bouncing off another player.
@export var repulsion_force : float = 1200.
## Horizontal velocity applied during directional jumps.
@export var forward_force : float = 500.
## Linear deceleration applied to horizontal movement when no input is active.
@export var horizontal_friction : float = 500.
## Cooldown time (in seconds) enforced between consecutive jumps.
@export var jump_cooldown : float = .1

@export_group('Visual Assets')
## Player texture.
@export var active_texture : Texture2D
## Texture displayed when the player dies.
@export var dead_texture : Texture2D
## Pool of textures used for generating random cosmetic feather particles.
@export var feather_textures : Array[Texture2D]

@export_group('Audio Assets')
## Sound effect played when player jumps.
@export var flap_sound : AudioStreamPlayer
## Sound effect played when player hits a remote player.
@export var knockback_sound : AudioStreamPlayer
## Sound effect played when player loses all their lives.
@export var death_sound : AudioStreamPlayer
## Sound effect played when player scores.
@export var score_sound : AudioStreamPlayer

const FALL_MULTIPLIER : float = 1.8
const MAX_FALL_SPEED : float = 1000.
const MAXIMUM_FEATHERS : int = 3

static var base_gravity : float = ProjectSettings.get_setting('physics/2d/default_gravity')
static var static_jump_force : float

var original_scale : Vector2
var cooldown_timer : float = 0.0
var is_control_enabled : bool = true

# Dependencies
@onready var sprite : Sprite2D = $Sprite2D
@onready var collision : CollisionShape2D = $CollisionShape2D
@onready var tails_container : Node2D = $Tail
@onready var wings_container : Node2D = $Wings
@onready var wings_animator : AnimationPlayer = $Wings/AnimationPlayer
@onready var visible_on_screen_notificer : VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D

func _ready() -> void:
	sprite.texture = active_texture
	original_scale = sprite.scale
	static_jump_force = jump_force
	base_aces = aces

	wings_animator.animation_finished.connect(func(anim_name : String) -> void:
		if anim_name != 'RESET':
			wings_animator.play('RESET')
	)

	visible_on_screen_notificer.screen_exited.connect(exit_view.emit)
	visible_on_screen_notificer.screen_entered.connect(enter_view.emit)
	
	exit_view.connect(func():
		if not is_control_enabled: return
		_take_damage(99999)
	)

	if aces <= 0: _take_damage() # in case my dumbass set player lives to 0 by accident

func _process(delta : float) -> void:
	if not is_control_enabled: return

	_update_cooldown(delta)
	_handle_screen_touch_input()

func _physics_process(delta : float) -> void:
	_apply_gravity(delta)
	_apply_friction(delta)

	move_and_slide()

	# note for future: I may consider throttling global network updates 
	# instead of running them on every single physics frame step.
	Network.set_player_position(position)

	_handle_direction_and_rotation(delta)
	_process_collisions()

func _take_damage(amount : int = 1, impact_normal : Vector2 = Vector2.ZERO) -> void:
	# TO-DO: there is a bug of multiple collision when holding screen & hiting obstacle, need to add colldown for damage too
	if not is_control_enabled: return

	var launch_direction : Vector2

	if impact_normal != Vector2.ZERO:
		launch_direction = impact_normal
		if launch_direction.y == 0: # if player hit a side wall
			launch_direction.y = -0.5 # add a slight upward lift
			launch_direction = launch_direction.normalized()
	else:
		var facing_dir : float = -1.0 if sprite.flip_h else 1.0
		launch_direction = Vector2(-facing_dir, -0.5).normalized()

	velocity = launch_direction * (repulsion_force / 2)
	if death_sound: death_sound.play()

	if aces - amount <= 0:
		aces = 0
		damaged.emit(0)
		_die()
		return

	aces -= amount
	damaged.emit(aces)

func _die() -> void:
	if not is_control_enabled: return
	is_control_enabled = false

	sprite.texture = dead_texture
	died.emit()
	wings_container.hide()

	_begin_respawn_sequence()
	Network.set_render(false)

func _begin_respawn_sequence() -> void:
	if is_control_enabled: return

	if respawn_delay > 0:
		var timer : Timer = Timer.new()
		print(timer)
		timer.wait_time = 1.0
		add_child(timer)
		timer.start()

		for i in respawn_delay:
			respawn_countdown.emit(respawn_delay - i)
			await timer.timeout

		timer.queue_free()

	for child in tails_container.get_children():
		child.hide()
		child.queue_free()

	sprite.texture = active_texture
	wings_container.show()
	position = Vector2.ZERO
	velocity = Vector2.UP * jump_force
	is_control_enabled = true # TO-DO: if the player dies too far from Vector2.ZERO they end up exiting the camera view, so it triggers another death. Need to fix that later
	aces = base_aces

	respawned.emit()
	Network.set_render(true)

# inputs

func _update_cooldown(delta : float) -> void: if cooldown_timer > 0.0: cooldown_timer -= delta

func _unhandled_input(event : InputEvent) -> void:
	if not is_control_enabled: return
	if cooldown_timer > 0.0: return
	get_viewport().set_input_as_handled()

	if event.is_action_pressed('Left', true) : _execute_jump(-1)
	if event.is_action_pressed('Right', true): _execute_jump(1)

func _handle_screen_touch_input() -> void:
	if cooldown_timer > 0.0: return
	get_viewport().set_input_as_handled()

	if Input.is_action_pressed('Jump', true):
		var screen_middle : float = get_viewport_rect().size.x / 2.0
		var touch_x : float = get_viewport().get_mouse_position().x
		var direction : int = 1 if touch_x > screen_middle else -1
		_execute_jump(direction)

# arcade physics and movement

func _apply_gravity(delta : float) -> void:
	var current_gravity : float = base_gravity
	if velocity.y > 0: current_gravity *= FALL_MULTIPLIER
	velocity.y = min(velocity.y + current_gravity * delta, MAX_FALL_SPEED)

func _apply_friction(delta : float) -> void:
	velocity.x = move_toward(velocity.x, 0, horizontal_friction * delta)

func _execute_jump(direction : int) -> void:
	cooldown_timer = jump_cooldown

	velocity.y = -jump_force
	var current_forward_force : float = forward_force
	# if we have horizontal momentum, and it opposes our input direction, halve the force
	if velocity.x != 0 and sign(velocity.x) != sign(direction):
		current_forward_force = forward_force / 2.

	velocity.x = current_forward_force * direction

	# juice
	jump.emit()
	_play_jump_effects(direction)

func _handle_direction_and_rotation(delta : float) -> void:
	# if not is_control_enabled: return

	if velocity.x != 0: sprite.flip_h = velocity.x < 0
	var direction_sign : float = -1.0 if sprite.flip_h else 1.0

	wings_container.position.x = abs(wings_container.position.x) * direction_sign * -1

	var target_angle : float = deg_to_rad(-30.0) if velocity.y < 0 else deg_to_rad(90.0)
	var lerp_speed : float = 20.0 if velocity.y < 0 else 4.0
	rotation = lerp_angle(rotation, target_angle * direction_sign, lerp_speed * delta)

# collision

func _process_collisions() -> void:
	for i in range(get_slide_collision_count()):
		var collision_data := get_slide_collision(i)
		var collider := collision_data.get_collider() as Node
		if not collider: continue

		if collider.is_in_group('Players'): _handle_knockback(collider)
		elif collider.is_in_group('Damageable') and is_control_enabled:
			_take_damage(1, collision_data.get_normal())
			break # often godot will generate multiple collision contacts in a single physics call, this break prevents double damage

func _handle_knockback(collider : Node2D) -> void:
	var push_direction : Vector2 = (global_position - collider.global_position).normalized()
	velocity = push_direction * repulsion_force
	remote_player_knockback.emit()
	if knockback_sound: knockback_sound.play()

# juice

func _play_jump_effects(direction : int) -> void:
	# squash and stretch
	sprite.scale = sprite.scale + Vector2(0.7, -0.3) 
	var sprite_tween := create_tween()
	sprite_tween.tween_property(sprite, 'scale', original_scale, 0.2).set_trans(Tween.TRANS_ELASTIC)

	wings_animator.play('flap')
	if flap_sound: flap_sound.play()
	Input.vibrate_handheld(25, 0.5)

	_generate_feathers(direction)

func _generate_feathers(direction : int) -> void:
	if feather_textures.is_empty(): return
	@warning_ignore('integer_division')
	var feathers_per_texture : int = MAXIMUM_FEATHERS / feather_textures.size()
	if feathers_per_texture <= 0: return

	for texture in feather_textures:
		var particles := CPUParticles2D.new()
		_configure_feather_particle(particles, texture, direction, feathers_per_texture)

		tails_container.add_child(particles)
		particles.finished.connect(particles.queue_free)
		particles.emitting = true

func _configure_feather_particle(particles : CPUParticles2D, texture : Texture2D, direction : int, amount : int) -> void:
	particles.texture = texture
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.lifetime = 4.0
	particles.amount = amount
	particles.scale_amount_min = sprite.scale.x
	particles.scale_amount_max = sprite.scale.x
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	particles.emission_sphere_radius = 50.0
	particles.local_coords = false
	particles.direction = Vector2(-direction, -1)
	particles.spread = 45.0
	particles.initial_velocity_min = 250.0
	particles.initial_velocity_max = 350.0
	particles.z_index = -4

# score

func increase_score(amount : int = 1) -> void:
	if amount <= 0: return

	score += amount
	score_changed.emit(score)
	if score_sound: score_sound.play()

# management

func disable() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	hide()

func enable() -> void:
	process_mode = Node.PROCESS_MODE_INHERIT
	show()
