class_name UP_HealthRegeneration
extends UP_BaseAbility

## Adds self healing to the player's character
##
## When active, adds [member regenerate_step_health_points]
## to the character's health and emits [signal health_regenerated] signal
## every [member regenerate_step_time] seconds.
##
## Requires [member health_path] set to work properly.

signal health_regenerated(points:float)

## Path to [UP_Health] node
@export_node_path("UP_Health") var health_path = NodePath("")

## Health points added every [member regenerate_step_time] seconds
@export var regenerate_step_health_points:float = 0.25

## Health regeneration interval (in seconds)
@export var regenerate_step_time:float = 1.0

var _health:UP_Health
var _timer = Timer.new()

func _ready():
    _health = get_node(health_path)
    if _health:
        _health.health_reset.connect(reset)
        _timer.wait_time = regenerate_step_time
        _timer.one_shot = false
        _timer.timeout.connect(_update)
        add_child(_timer)
        _timer.start()

func _update():
    if _health.is_alive():
        _health.change(regenerate_step_health_points)
        health_regenerated.emit(regenerate_step_health_points)

## Resets internal timers
func reset():
    _timer.stop()
    _timer.start()
