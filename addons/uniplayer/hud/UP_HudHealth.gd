extends Control

@export_node_path("UP_Health") var health_behaviour_path:NodePath = NodePath("")
var health_behaviour:UP_Health

func _ready():
    health_behaviour = get_node(health_behaviour_path)
    if health_behaviour:
        health_behaviour.connect("health_changed", _update)
        $%ProgressBar.max_value = health_behaviour.max_health
        _update()

func _update():
    $%ProgressBar.value = health_behaviour.health
