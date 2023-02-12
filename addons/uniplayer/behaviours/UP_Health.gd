extends UP_BaseAbility
class_name UP_Health

signal health_changed
signal health_reset

@export var max_health:float = 10.0
@export_node_path("UP_KillableBehaviour") var killable_behaviour_path:NodePath = NodePath("")

var health = max_health
var killable:UP_KillableBehaviour

func _ready():
    super()
    killable = get_node(killable_behaviour_path)
    emit_signal("health_changed")
    if killable:
        killable.connect("respawned", _reset)
    
    
func change(amount: float):
    var new_health = clampf(health + amount, 0, max_health)
    if not new_health == health:
        health = new_health
        emit_signal("health_changed")
        
        if health == 0 and killable:
            killable.kill()    


func is_alive():
    return not killable.is_killed if killable else false


func _reset():
    health = max_health
    emit_signal("health_changed")
    emit_signal("health_reset")
