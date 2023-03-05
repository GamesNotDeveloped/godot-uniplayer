extends UP_BaseAbility
class_name UP_DisplayInEditorOnly

## Removes all child nodes at runtime
##
## When active, it removes all child nodes at runtime, which are visible
## in the Editor (i.e. for debugging or to visualise something).
##
## When inactive, all child nodes will visible at runtime.
##
## [b]Changing active state at runtime has no effect.[/b]

func _ready():
    if active and not Engine.is_editor_hint():
        for x in get_children():
            remove_child(x)
            x.queue_free()
