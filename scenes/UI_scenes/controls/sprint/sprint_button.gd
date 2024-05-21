extends Node2D

var sprinting = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	



func _on_button_button_down():
	sprinting = true
	pass # Replace with function body.


func _on_button_button_up():
	sprinting = false
	pass # Replace with function body.
