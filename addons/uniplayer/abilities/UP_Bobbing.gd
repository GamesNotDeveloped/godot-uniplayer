class_name UP_Bobbing
extends UP_BaseAbility

## Base handler for camera bobbing for the Uniplayer Controller
##
## Provides interface for change the current state of bobbing of the [UP_PlayerBase],
## registering bobbing modifiers and automatic stabilization of bobbing.

@export_category("Dependencies")
@export_node_path("UP_RotationHelper") var rotation_helper_path:NodePath = NodePath("")
@export_node_path("Camera3D") var camera_path:NodePath = NodePath("")

@export_category("Configuration")
@export_range(0.0, 10.0) var BOB_SPEED = 0.9
@export_range(0.0, 10.0) var BOB_STABILIZE_SPEED = 1.0

var target_bob_rot_basis: Basis
var target_bob_pos: Vector3 = Vector3.ZERO
var target_bob_pos_offset: Vector3 = Vector3.ZERO
var bob_basis: Basis = Basis()

var rotation_helper:UP_RotationHelper
var camera:Camera3D

var bobbing_modifiers = []

var _bob_val = 0.0
var _spd = 1.0

func register_bobbing(target:Node):
    bobbing_modifiers.append(target)

func _ready():
    super()
    rotation_helper = get_node(rotation_helper_path)
    camera = get_node(camera_path)
    if not rotation_helper or not camera:
        active = false
    else:
        player.register_movement_ability(self)

func _process_movement(delta):
    if not active:
        return
        
    var _bob_quat = target_bob_rot_basis.get_rotation_quaternion()
    #target_bob_pos = Vector3.ZERO
    
    bob_basis = lerp(bob_basis,
        Basis(_bob_quat), clamp(_spd * delta, 0.0, 1.0)
    )
    
    # execute registered bobbing modifiers
     
    for mod in bobbing_modifiers:
        mod._process_bobbing(delta)

    # stabilize bobbing
    target_bob_pos = lerp(
        target_bob_pos, Vector3.ZERO, delta * BOB_STABILIZE_SPEED * 4.0
    )    
    
    target_bob_rot_basis = lerp(target_bob_rot_basis,
        Basis(),
        delta * BOB_STABILIZE_SPEED * 2.0
    )

    rotation_helper.transform.basis = lerp(rotation_helper.transform.basis,
        rotation_helper.transform.basis * bob_basis,
        delta
    )
    target_bob_pos_offset = lerp(target_bob_pos_offset, Vector3.ZERO, clamp(BOB_STABILIZE_SPEED * delta * 10.0, 0.0, 1.0))
    camera.position = camera.position.lerp(
        target_bob_pos + target_bob_pos_offset, clamp(_spd * delta, 0.0, 1.0)
    )   
    
    
func add_bobbing(x:Transform3D):
    target_bob_rot_basis *= x.basis
    target_bob_pos += x.origin

func get_bobbing():
    return Transform3D(target_bob_rot_basis, target_bob_pos)

func replace_bobbing(x: Transform3D):
    target_bob_rot_basis = x.basis
    target_bob_pos = x.origin   
    pass
