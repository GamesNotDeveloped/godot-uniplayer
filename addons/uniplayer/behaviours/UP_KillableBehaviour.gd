extends UP_BaseAbility
class_name UP_KillableBehaviour

# Responsibility:
# - make character killable 
# - handle respawning
# - store "last good" player position

signal killed
signal respawned
signal game_stopped

enum RespawnType {DisableControl, RespawnFromStart, RespawnLastGood, EmitStopSignal, Quit}

@export var respawn_type:RespawnType = RespawnType.DisableControl

var initial_transform:Transform3D
var last_good_transform:Transform3D
var is_killed:bool = false

func _ready():
    super()
    initial_transform = player.global_transform
    player.connect("reset", _reset)
    
func kill(force_respawn_type=null):
    if not active:
        return 
    is_killed = true
    
    emit_signal("killed")
    var x = force_respawn_type if force_respawn_type else respawn_type
    
    match x:
        RespawnType.DisableControl:
            player.controllable = false
        RespawnType.RespawnFromStart:
            player.global_transform = initial_transform
            player.emit_signal("reset")
            is_killed = false
            emit_signal("respawned")
        RespawnType.EmitStopSignal:
            emit_signal("game_stopped")
        RespawnType.Quit:
            get_tree().quit()

func _reset():
    is_killed = false
