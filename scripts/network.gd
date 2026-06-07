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

extends Node

## Emitted when a network configuration or connection error occurs.
signal error(message : String)

const PORT : int = 11037
const BROADCAST_INTERVAL : float = 0.1
const ABSENCE_THRESHOLD_SECONDS : int = 2
const NETWORK_PLAYER_PREFAB : PackedScene = preload('res://scenes/prefabs/remote_player.tscn')

var server : PacketPeerUDP = PacketPeerUDP.new()
var detected_players : Dictionary
var broadcast_timer : Timer
var data : Dictionary = {
	'header': '##CROW',
	'id': OS.get_unique_id(),
	'nickname': 'aa',
	'join_time': Time.get_unix_time_from_system(),
	'version': ProjectSettings.get_setting('application/config/version')
}

var rendering : bool = false

func _ready() -> void:
	detected_players.clear()

	if server.bind(PORT) != OK:
		error.emit('Couldn\'t bind to port: ' + str(PORT))
		return

	server.set_broadcast_enabled(true)
	server.set_dest_address('255.255.255.255', PORT)
	
	broadcast_timer = Timer.new()
	broadcast_timer.wait_time = BROADCAST_INTERVAL
	broadcast_timer.timeout.connect(_broadcast)
	add_child(broadcast_timer)
	broadcast_timer.start()

func _process(_delta : float) -> void:
	if not server: return

	while server.get_available_packet_count() > 0:
		var packet = bytes_to_var(server.get_packet())
		if not packet is Dictionary: continue
		if not 'header' in packet: continue
		if packet.header != '##CROW': continue
		
		# Note for future: Check version here later
		if not 'id' in packet: continue
		if packet.id == data.id: continue

		if packet.id in detected_players:
			if not 'position' in packet:
				detected_players[packet.id].rendering = false
				continue
 
			if 'position' in packet and detected_players[packet.id].rendering:
				detected_players[packet.id].target_position = packet.position
				continue

			detected_players[packet.id].target_position = packet.position
			detected_players[packet.id].position = packet.position
			detected_players[packet.id].rendering = true

			continue

		var current_scene := get_tree().current_scene
		if not current_scene: return
		
		var new_remote_player := NETWORK_PLAYER_PREFAB.instantiate() as RemotePlayer
		new_remote_player.id = packet.id
		new_remote_player.name = packet.id
		detected_players[packet.id] = new_remote_player
		new_remote_player.set_nickname(packet.id)

		if 'position' in packet:
			new_remote_player.target_position = packet.position
			new_remote_player.position = packet.position
		else:
			detected_players[packet.id].rendering = false

		current_scene.add_child(new_remote_player)

# public api

func set_player_position(player_position : Vector2) -> void: # did you like my absolute masterpiece networking code?
	data.position = player_position

func set_render(value : bool = true) -> void:
	rendering = value

# connection and broadcasting

func _broadcast() -> void:
	if not server: return
	if not 'nickname' in data: return
	if data.nickname.is_empty(): return

	var data_local := data.duplicate()
	print(rendering)

	if not rendering and 'position' in data:
		data_local.erase('position')

	var packet : PackedByteArray = var_to_bytes(data_local)
	server.set_dest_address('255.255.255.255', PORT)
	server.put_packet(packet)
