extends UP_BaseAbility
class_name UP_Kill_Y

# Responsibility;
# - automatically kill the player below specified world Y value

enum ForceRespawnType {UseDefault, RespawnFromStart, RespawnLastGood, Quit}

var _forced_respawn_map = {
    ForceRespawnType.UseDefault: null,
    ForceRespawnType.RespawnFromStart: UP_KillableBehaviour.RespawnType.RespawnFromStart,
    ForceRespawnType.RespawnLastGood: UP_KillableBehaviour.RespawnType.RespawnLastGood,
    ForceRespawnType.Quit: UP_KillableBehaviour.RespawnType.Quit,
}

@export_node_path("UP_KillableBehaviour") var killable_behaviour_path = NodePath("")
@export var force_respawn_type:ForceRespawnType = ForceRespawnType.RespawnFromStart

@export_range(0.01, 10) var check_interval = 1.0
@export var global_y_position = -10.0

var timer = Timer.new()
var killable_behaviour:UP_KillableBehaviour

func _ready():
    super()
    killable_behaviour = get_node(killable_behaviour_path)
    
    if killable_behaviour:
        timer.wait_time = check_interval
        timer.one_shot = false
        timer.connect("timeout", _update)
        add_child(timer)
        timer.start()
        
        player.register_control_ability(self)
    else:
        push_warning("UP_Kill_Y requires UP_KillableBehaviour to be set")

func _update():
    if not active:
        return
        
    if player.global_position.y < global_y_position:
        killable_behaviour.kill(_forced_respawn_map[force_respawn_type])

func _process_control(delta):
    pass
