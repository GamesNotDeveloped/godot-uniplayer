extends Node3D
class_name DisplayInEditorOnly


func _ready():
    if not Engine.is_editor_hint():
        for x in get_children():
            remove_child(x)
            x.queue_free()
