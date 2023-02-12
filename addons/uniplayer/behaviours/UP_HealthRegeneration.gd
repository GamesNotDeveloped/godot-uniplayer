extends UP_BaseAbility

signal health_change

@export_node_path("UP_Health") var health_behaviour_path = NodePath("")
@export var health_regenerate_step:float = 0.25 # HP
@export var health_regenerate_time:float = 1.0  # seconds

var health_behaviour:UP_Health
var timer = Timer.new()

func _ready():
    health_behaviour = get_node(health_behaviour_path)
    if health_behaviour:
        health_behaviour.connect("health_reset", _reset)
        timer.wait_time = health_regenerate_time
        timer.one_shot = false
        timer.connect("timeout", _update)
        add_child(timer)
        timer.start()

func _update():
    if health_behaviour.is_alive():
        health_behaviour.change(health_regenerate_step)

func _reset():
    timer.stop()
    timer.start()
