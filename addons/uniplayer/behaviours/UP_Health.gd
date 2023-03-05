extends UP_BaseAbility
class_name UP_Health

## Adds ability to control character's health
##
## Exposes [method change] and [member health] to control health from the outside.
## It has no logic of changing the health.
## If [member killable_behaviour_path] is set, a [method UP_KillableBehaviour.kill]
## will be called when [member health] drops to 0 or below.

signal health_changed
signal health_reset

## Maximum health value. It is used by [method reset] and at initialization.
@export var max_health:float = 10.0

## Path to [UP_KillableBehaviour] node. If set, the player's character will be killed when
## health drops to 0 or below.
@export_node_path("UP_KillableBehaviour") var killable_path:NodePath = NodePath("")

## A current health amount
var health := max_health:
    set(x):
        var new_health = clampf(x, 0.0, max_health)
        if not health == new_health:
            health = new_health
            health_changed.emit()
            if health == 0 and _killable:
                _killable.kill()
                    
var _killable:UP_KillableBehaviour

func _ready():
    super()
    _killable = get_node(killable_path)
    health_changed.emit()
    if _killable:
        _killable.respawned.connect(reset)
    
## Changes the [member health] by provided amount.
## Currently it is an equivalent of [code]health += amount[/code]
func change(amount: float):
    health += amount

## Returns true if player's character is alive, false othervise.
## Always returns true if [member killable_path] is not set.
func is_alive() -> bool:
    return not _killable.is_killed if _killable else true

## Sets [member health] to [member max_health], then emits a [signal health_reset] signal.
func reset():
    health = max_health
    health_reset.emit()
