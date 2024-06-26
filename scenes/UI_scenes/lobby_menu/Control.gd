extends Control

signal  found_server
signal  server_removed
signal joinGame(ip)
var broadcastTimer : Timer


var RoomInfo = {"name":"name", "playerCount": 0, "ip":"","players": GameManager.Players}
var broadcaster : PacketPeerUDP
var listner : PacketPeerUDP
@export var listenPort : int = 8911
@export var broadcastPort : int = 8912
@export var broadcastAddress : String = '255.255.255.255'
@export var serverInfo : PackedScene

var currentRoomPlayers = {}

var rooms = {}
# Called when the node enters the scene tree for the first time.
func _ready():
	var address = "no ip aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
	var addresses = []
	for ip in IP.get_local_addresses():
		if ip.begins_with("10.") or ip.begins_with("172.16.") or ip.begins_with("192.168."):
			addresses.push_back(ip)
	if addresses.size() > 0:
		address = addresses[0]
		RoomInfo.ip = address
		print(address)
	$"../ipadd".text = address
	broadcastTimer = $BroadcastTimer
	setUp()
	pass # Replace with function body.


func setUp():
	listner = PacketPeerUDP.new()
	var ok = listner.bind(listenPort)
	
	if ok == OK:
		print("Bound to listen Port "  + str(listenPort) +  " Successful!")
		$Label2.text="Bound To Listen Port: true"
	else:
		print("Failed to bind to listen port!")
		$Label2.text="Bound To Listen Port: false"

func setUpBroadCast(name):
	RoomInfo.name = name
	RoomInfo.playerCount = GameManager.Players.size()
	broadcaster = PacketPeerUDP.new()
	broadcaster.set_broadcast_enabled(true)
	broadcaster.set_dest_address(broadcastAddress, listenPort)
	
	var ok = broadcaster.bind(broadcastPort)
	
	if ok == OK:
		print("Bound to Broadcast Port "  + str(broadcastPort) +  " Successful!")
	else:
		print("Failed to bind to broadcast port!")
		
	$BroadcastTimer.start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if listner.get_available_packet_count() > 0:
		var serverip = listner.get_packet_ip()
		var serverport = listner.get_packet_port()
		var bytes = listner.get_packet()
		var data = bytes.get_string_from_ascii()
		var roomInfo = JSON.parse_string(data)
		#print(serverip + "/n-" + str(roomInfo))
		if(serverip != ""):
			if(!rooms.has(str(serverip))):
				rooms[serverip] = {
					"name": roomInfo.name,
					"playerC": roomInfo.playerCount
				}
		#print(currentRoomPlayers)
		#print("server Ip: " + serverip +" serverPort: "+ str(serverport) + " room info: " + str(roomInfo))
		if(!currentRoomPlayers.has(roomInfo.ip)):
					currentRoomPlayers[roomInfo.ip] ={
						"players": roomInfo.players
					}
		for i in $Panel/VBoxContainer.get_children():
			if i.name == roomInfo.name:
				i.get_node("IP").text = roomInfo.ip
				i.get_node("PlayerCount").text = str(roomInfo.playerCount)
				currentRoomPlayers[roomInfo.ip] ={
					"players": roomInfo.players
				}
				return

		var currentInfo = serverInfo.instantiate()
		currentInfo.name = roomInfo.name
		currentInfo.get_node("Name").text = roomInfo.name
		currentInfo.get_node("IP").text = serverip
		currentInfo.get_node("PlayerCount").text = str(roomInfo.playerCount)
		currentInfo.get_node("Button").text = "Join " + roomInfo.name
		$Panel/VBoxContainer.add_child(currentInfo)
		print(serverip)
		currentInfo.joinGame.connect(joinbyIp)
		pass
	pass


func _on_broadcast_timer_timeout():
	#print("Broadcasting Game!")
	RoomInfo.playerCount = GameManager.Players.size()
	var data = JSON.stringify(RoomInfo)
	var packet = data.to_ascii_buffer()
	broadcaster.put_packet(packet)
	pass # Replace with function body.

func cleanUp():
	listner.close()
	
	$BroadcastTimer.stop()
	if broadcaster != null:
		broadcaster.close()

func _exit_tree():
	cleanUp()

func joinbyIp(ip):
	
	print(ip)
	joinGame.emit(ip)
