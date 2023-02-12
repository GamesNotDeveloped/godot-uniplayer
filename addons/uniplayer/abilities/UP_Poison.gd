extends UP_BaseAbility
class_name UP_Poison

# Responsibility:
# - when active, it is poisoning the player's health
#
# This behavior can be used by UP_Hunger or similar component,
# when player eats a poisoned or spoiled food.


@export_category("Dependencies")
@export_node_path("UP_Health") var health_behaviour_path = NodePath("")

@export_category("Configuration")
@export var poison_tick_time = 1.0
@export var poison_tick_value = 1.0

var health_behaviour:UP_Health

var timer = Timer.new()

func _ready():
    health_behaviour = get_node(health_behaviour_path)
    if health_behaviour:
        health_behaviour.connect("health_reset", _reset)
        timer.wait_time = poison_tick_time 
        timer.one_shot = false
        timer.connect("timeout", _update)
        add_child(timer)
        timer.start()
    
    
func _update():
    if active:
        health_behaviour.change(-poison_tick_value)

func _reset():
    timer.stop()
    timer.start()
