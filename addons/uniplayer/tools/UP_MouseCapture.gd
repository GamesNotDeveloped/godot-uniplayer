extends UP_Tool
class_name UP_MouseCapture

var captured = true
@export var ACTION_MOUSE_CAPTURE = "ui_cancel"


func _ready():
    _update()
    

func _input(event):
    if event.is_action_pressed(ACTION_MOUSE_CAPTURE):
        captured = not captured
        _update()

func _update():
    Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if captured else Input.MOUSE_MODE_VISIBLE
