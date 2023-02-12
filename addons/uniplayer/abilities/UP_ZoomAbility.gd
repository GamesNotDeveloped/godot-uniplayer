extends UP_BaseAbility

signal zoomed_in
signal zoomed_out

# Responsibility:
# - zooming (changing camera's fov on demand)

@export_node_path("Camera3D") var camera_path:NodePath = NodePath("")
@export_node_path("UP_KillableBehaviour") var killable_behaviour_path:NodePath = NodePath("")
@export_range(0, 100.0) var zoom_fov = 30.0
@export_range(0.01, 10.0) var fov_speed_factor = 5.0

@export_subgroup("Actions")
@export var ACTION_ZOOM = "zoom"

var DEFAULT_ACTIONS = [
    [ACTION_ZOOM, null, MOUSE_BUTTON_RIGHT],                                                                 
]

var camera:Camera3D
var killable_behaviour:UP_KillableBehaviour
var default_fov = 70.0
var _target_fov = default_fov


func _ready():
    super()
    killable_behaviour = get_node(killable_behaviour_path)
    camera = get_node(camera_path) as Camera3D
    player.register_default_input_bindings(DEFAULT_ACTIONS)
    if camera:
        default_fov = camera.fov
        _target_fov = default_fov
    if killable_behaviour:
        killable_behaviour.connect("killed", _killed)
        killable_behaviour.connect("respawned", _respawned)
        
func _input(event):
    if event.is_action_pressed("zoom"):
        _target_fov = zoom_fov
        emit_signal("zoomed_in")
    elif event.is_action_released("zoom"):
        _target_fov = default_fov
        emit_signal("zoomed_out")
        

func _physics_process(delta):
    if camera and active:
        camera.fov = lerpf(camera.fov, _target_fov, delta * fov_speed_factor)

func _killed():
    active = false
    
func _respawned():
    active = true
