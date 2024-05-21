extends CharacterBody2D

signal body_entered(id)
signal body_exited(id)
signal game_end(bo)
var player_speed = 500
@onready var animation_tree = $AnimationTree
@onready var animation_mode = animation_tree.get("parameters/playback")
@onready var joystick = $Camera2D/joystick
@onready var sprint_button = $Camera2D/sprint_button
@onready var lb = $Camera2D/VBoxContainer
var stamina = 50
@export var can_tag = true
# Called when the node enters the scene tree for the first time.
func _ready():
	handle_animations(Vector2(0, 1))
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		var curId = multiplayer.get_unique_id()
		$Camera2D.make_current()
		joystick.visible = true
		sprint_button.visible = true
		lb.visible = true
		var input_direction = Vector2(
			Input.get_action_strength("right") - Input.get_action_strength("left"),
			Input.get_action_strength("down") - Input.get_action_strength("up")
		)
		if(sprint_button.sprinting || (Input.get_action_strength("shift") > 0)):
			player_speed = 900
			stamina-=1*delta
		else:
			player_speed = 500
			stamina += 1*delta
			
		var joystick_vector = joystick.posVector
		
		
		velocity = (player_speed*joystick_vector) + (input_direction*player_speed)
		handle_animations(joystick_vector)
		move_and_slide()
		pick_new_state()
	pass

#handles animation changes
func handle_animations(mov_dir):
	if(velocity != Vector2.ZERO):
		animation_tree.set("parameters/walk/blend_position", mov_dir)
		animation_tree.set("parameters/idle/blend_position", mov_dir)

#changes states based on velocity
func pick_new_state():
	if(velocity != Vector2.ZERO):
		animation_mode.travel("walk")
	else:
		animation_mode.travel("idle")

func _on_area_2d_body_entered(body):
	if !(body is CharacterBody2D):
		return
	if body != self:
		var bodyId = int(str(body.name))
		if(GameManager.Players.size() >= 1):
			if(GameManager.Players[bodyId].is_it && can_tag):
				$Area2D/CollisionShape2D.set_deferred("disabled", true)
				if(body.has_node("Area2D")):
					var area = body.get_node("Area2D")
					if(area.has_node("CollisionShape2D")):
						var colArea = area.get_node("CollisionShape2D")
						colArea.set_deferred("disabled", true)
				GameManager.Players[int(str(self.name))].is_it = true
				GameManager.Players[bodyId].is_it = false
				body_entered.emit(true)
				can_tag = false
				body.can_tag = false
				$TagTimer.start(3)
				$ColTimer.start(3)
				if(body.has_node("TagTimer")):
					var node = body.get_node("TagTimer") as Timer
					node.start(3)
				if(body.has_node("ColTimer")):
					var node = body.get_node("ColTimer") as Timer
					node.start(3)
				if(multiplayer.is_server()):
					syncGM.rpc(GameManager.Players)
			elif(GameManager.Players[multiplayer.get_unique_id()].is_it && can_tag):
				$Area2D/CollisionShape2D.set_deferred("disabled", true)
				if(body.has_node("Area2D")):
					var area = body.get_node("Area2D")
					if(area.has_node("CollisionShape2D")):
						var colArea = area.get_node("CollisionShape2D")
						colArea.set_deferred("disabled", true)
				GameManager.Players[int(str(self.name))].is_it = false
				GameManager.Players[bodyId].is_it = true
				body_entered.emit(true)
				can_tag = false
				body.can_tag = false
				$TagTimer.start(3)
				$ColTimer.start(3)
				if(body.has_node("TagTimer")):
					var node = body.get_node("TagTimer") as Timer
					node.start(3)
				if(body.has_node("ColTimer")):
					var node = body.get_node("ColTimer") as Timer
					node.start(3)
				if(multiplayer.is_server()):
					syncGM.rpc(GameManager.Players)
	
	pass # Replace with function body.

@rpc("authority", "reliable", "call_local")
func syncGM(arr):
	GameManager.Players = arr
	print(GameManager.Players)
	if(multiplayer.is_server()):
		print("^ from server")
	else:
		print("^ from client")
	return

func sprint(is_sprinting):
	if is_sprinting:
		player_speed = 900
	else:
		player_speed = 500

func _on_col_timer_timeout():
	$Area2D/CollisionShape2D.set_deferred("disabled", false)
	pass # Replace with function body.


func _on_tag_timer_timeout():
	can_tag = true
	pass # Replace with function body.




func _on_game_timer_timeout():
	if(multiplayer.is_server()):
		syncGM.rpc(GameManager.Players)
	var rankings = []
	for p in GameManager.Players:
		rankings.push_back(GameManager.Players[p])
	rankings.sort_custom(func(a, b): return a.score > b.score)
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		$winner.text = "Winner is: " + str(rankings[0].name)
		$winner.visible = true
	$EndTimer.start(5)
	pass # Replace with function body.




func _on_end_timer_timeout():
	if(multiplayer.is_server()):
		endGame.rpc()
	pass # Replace with function body.
	
@rpc ("authority", "call_local")
func endGame():
	GameManager.Players = {}
	if(get_tree().root.has_node("multiplayer_lobby")):
		print("found")
		var map = get_tree().root.get_node("multiplayer_lobby") as Control
		map.visible = true
	if(get_tree().root.has_node("basic_map")):
		print("found")
		var map = get_tree().root.get_node("basic_map")
		get_tree().root.remove_child(map)
	
	return
