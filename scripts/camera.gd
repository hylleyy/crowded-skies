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

extends Camera2D

const MAX_TRAUMA : float = 1.0
const MIN_TRAUMA : float = 0.0
const NOISE_SPEED : float = 50.0
const REST_LERP_SPEED : float = 5.0

const NOISE_X_OFFSET : float = 10.0
const NOISE_Y_OFFSET : float = 20.0
const NOISE_ROTATION_OFFSET : float = 0.0

@export_group("Camera")
## The Player node that the camera will smoothly follow.
@export var target : Player
## The smoothing weight used for linear interpolation (lerp) when tracking the target.
@export var weight : float = 2.0

@export_group("Trauma")
## The rate at which the camera shake (trauma) decays over time.
@export var decay : float = 0.8
## The maximum pixel offset allowed for camera shake along the X and Y axes.
@export var max_offset : Vector2 = Vector2(100.0, 75.0)
## The maximum rotational angle (in radians) allowed for camera shake rolling.
@export var max_roll : float = 0.1
## The noise generator configuration used to create organic, non-repetitive screen shake.
@export var noise : FastNoiseLite

var _trauma : float = 0.0
var _trauma_power : int = 2
var _noise_y : float = 0.0

func _ready() -> void:
	if not target: return

	target.jump.connect(func(): add_trauma(0.15))
	target.died.connect(func(): add_trauma(1.0))
	target.remote_player_knockback.connect(func(): add_trauma(0.8))

	if noise: return

	noise = FastNoiseLite.new()
	noise.seed = randi()
	noise.frequency = 0.05

func _physics_process(delta : float) -> void:
	if not target: return
	global_position.x = lerp(global_position.x, target.global_position.x, weight * delta)

func _process(delta : float) -> void:
	if not target: return

	if _trauma > MIN_TRAUMA:
		_process_trauma_decay(delta)
		_shake()
	else: _reset_camera_effects(delta)

## Adds a specified amount of trauma to trigger or increase screen shake, capped at maximum.
func add_trauma(amount : float) -> void: 
	_trauma = min(_trauma + amount, MAX_TRAUMA)

func _process_trauma_decay(delta : float) -> void:
	_trauma = max(_trauma - decay * delta, MIN_TRAUMA)
	_noise_y += delta * NOISE_SPEED

func _shake() -> void:
	var shake_intensity : float = pow(_trauma, _trauma_power)
	rotation = max_roll * shake_intensity * noise.get_noise_2d(NOISE_ROTATION_OFFSET, _noise_y)
	offset.x = max_offset.x * shake_intensity * noise.get_noise_2d(NOISE_X_OFFSET, _noise_y)
	offset.y = max_offset.y * shake_intensity * noise.get_noise_2d(NOISE_Y_OFFSET, _noise_y)

func _reset_camera_effects(delta : float) -> void:
	offset = offset.lerp(Vector2.ZERO, REST_LERP_SPEED * delta)
	rotation = lerp(rotation, 0.0, REST_LERP_SPEED * delta)
