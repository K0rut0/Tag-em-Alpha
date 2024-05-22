extends Control

@export var address = "192.168.1.1"
@export var port = 35000
var peer
var addresses = []
var sprite = "male"
# Called when the node enters the scene tree for the first time.
func _ready():
	print("ready")
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	
	if "--server" in OS.get_cmdline_args():
		hostGame()
	
	$Control.joinGame.connect(JoinByIP)
	pass # Replace with function body.



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass


@rpc("any_peer")
func send_player_info(username, ids, sp):
	if !GameManager.Players.has(ids):
		GameManager.Players[ids] = {
			"id": ids,
			"name": username,
			"is_it": false,
			"sprites": sp,
			"score": 0
		}
	if multiplayer.is_server():
		for i in GameManager.Players:
			send_player_info.rpc(GameManager.Players[i].name, i, sprite)

@rpc("any_peer", "call_local")
func start_game():
	if(multiplayer.get_unique_id() == 1):
		var PlayerArr = []
		for i in GameManager.Players:
			PlayerArr.push_back(GameManager.Players[i])
		#sort players by id so they dont overlap in spawn
		PlayerArr.sort_custom(func(a, b): return a.id < b.id)
		var it = randi_range(0, PlayerArr.size()-1)
		GameManager.Players[PlayerArr[it].id].is_it = true
		syncInitState.rpc(GameManager.Players)
	var scene = load("res://scenes/level_scenes/basic_map/basic_map.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()

@rpc("authority")
func syncInitState(gm):
	GameManager.Players = gm
	print("synced")
	print(GameManager.Players)
	if(multiplayer.is_server()):
		print(" --server--")
	else:
		print("--client--")
	if(multiplayer.is_server()):
		syncInitState.rpc(gm)
	

func peer_connected(id):
	print("Player connected " +  str(id))
	
func peer_disconnected(id):
	print("Player disconnected " +  str(id))

func connected_to_server():
	print("Connected to Server")
	send_player_info.rpc_id(1, $username.text ,multiplayer.get_unique_id(), sprite)
func connection_failed():
	print("Could not connect")

func hostGame():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, 2)
	if error != OK:
		print("cannot host: " + str(error))
		return
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting For Players!")

func _on_host_button_down():
	hostGame()
	send_player_info($username.text, multiplayer.get_unique_id(), sprite)
	
	$Control.setUpBroadCast($username.text + "'s server")
	pass # Replace with function body.
	
func _on_join_button_down():
	
	JoinByIP(address)
	pass # Replace with function body.

	
func JoinByIP(ip):
	if(!multiplayer.is_server()):
		send_player_info.rpc_id(1, $username.text ,multiplayer.get_unique_id(), sprite)
	address = ip
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	pass

func _on_start_button_down():
	start_game.rpc()
	pass # Replace with function body.

func _on_back_button_down():
	print("wow")
	get_tree().change_scene_to_file("res://scenes/UI_scenes/main_menu/main_menu.tscn")
	pass # Replace with function body.


func _on_male_button_down():
	sprite = "male"
	pass # Replace with function body.


func _on_female_button_down():
	sprite = "female"
	pass # Replace with function body.
