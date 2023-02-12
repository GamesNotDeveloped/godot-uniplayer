class_name UP_HeadRotationAbility
extends UP_BaseAbility

# Responsibility:
# * rotate player head by mouse or joypad

@export_node_path("UP_RotationHelper") var rotation_helper_path: NodePath = NodePath("")

@export_subgroup("General")
@export_range(0.001, 1.0) var LOOK_FRICTION = 0.8
@export_subgroup("Mouse")
@export_range(0.001, 25.0) var mouse_rotation_speed = 15.0
@export_range(0.001, 1.0) var mouse_rotation_friction = 0.8
@export_range(0.001, 2.0) var MOUSE_SENSITIVITY = 0.2
@export_subgroup("Joypad")
@export_range(0.01, 5.0) var JOY_LOOK_SPEED_FACTOR = 2.0
@export_subgroup("Actions")
@export var ACTION_LOOK_LEFT = "look_left"                                                          
@export var ACTION_LOOK_RIGHT = "look_right"                                                        
@export var ACTION_LOOK_UP = "look_up"                                                              
@export var ACTION_LOOK_DOWN = "look_down" 

const ROTATION_SLERP_FACTOR = 2.0

var DEFAULT_ACTIONS = [
    [ACTION_LOOK_LEFT, null, null],                                                                 
    [ACTION_LOOK_RIGHT, null, null],                                                                
    [ACTION_LOOK_UP, null, null],                                                                   
    [ACTION_LOOK_DOWN, null, null],
]

var target_basis: Basis
var target_rotation_helper_basis: Basis
var joy_look = Vector2.ZERO
var target_joy_look = Vector2.ZERO
var cam_rot = Vector3.ZERO
var target_cam_rot = Vector3.ZERO
var cam_rot_spd = Vector2.ZERO


var rotation_helper:Node3D
var initial_rotation_helper_transform = Transform3D()

func _ready():
    super()
    rotation_helper = get_node(rotation_helper_path)
    player.register_control_ability(self)
    player.register_default_input_bindings(DEFAULT_ACTIONS)
    player.connect("reset", _reset)
    target_basis = player.transform.basis

func _reset():
    #if rotation_helper:
    #    initial_rotation_helper_transform = rotation_helper.transform
    target_cam_rot = Vector3.ZERO
    cam_rot = Vector3.ZERO
    target_joy_look = Vector2.ZERO
    joy_look = Vector2.ZERO
    target_rotation_helper_basis = initial_rotation_helper_transform.basis
    target_basis = player.transform.basis
    
func _input(event):                                                                                 
    if event is InputEventMouseMotion:
        target_cam_rot += Vector3(event.relative.y, event.relative.x, 0)
        cam_rot_spd = event.velocity
        target_joy_look = Vector2(
            Input.get_action_strength(ACTION_LOOK_RIGHT)-Input.get_action_strength(ACTION_LOOK_LEFT),
            Input.get_action_strength(ACTION_LOOK_UP)-Input.get_action_strength(ACTION_LOOK_DOWN)
        ) * JOY_LOOK_SPEED_FACTOR                                                                       
            
func _process_control(delta):
    if not rotation_helper:
        return

    var is_alive = true  # TODO: support health

    cam_rot = lerp(cam_rot, target_cam_rot, (1.0-delta)*0.5 * LOOK_FRICTION)
    joy_look = lerp(joy_look, target_joy_look, (1.0-delta)*0.5 * LOOK_FRICTION)

    var new_rot = Vector3(cam_rot.x, cam_rot.y, 0)
    var cam_spd =  abs(cam_rot_spd.x) * 0.02

    target_basis = target_basis.rotated(
        Vector3.UP, -deg_to_rad(new_rot.y * MOUSE_SENSITIVITY)
    ).orthonormalized()

    target_basis = target_basis.rotated(
        Vector3.UP, -deg_to_rad(joy_look.x)
    ).orthonormalized()

    if is_alive:
        player.transform.basis = player.transform.basis.slerp(
            target_basis, mouse_rotation_friction*delta*mouse_rotation_speed*ROTATION_SLERP_FACTOR
        ).orthonormalized()

    target_rotation_helper_basis = target_rotation_helper_basis.rotated(
        Vector3.RIGHT,
        -deg_to_rad(new_rot.x *  MOUSE_SENSITIVITY)
    )
    target_rotation_helper_basis = target_rotation_helper_basis.rotated(
        Vector3.RIGHT,
        deg_to_rad(joy_look.y)
    )

    var bob_basis = Basis()  # FIXME: bobbing

    rotation_helper.transform.basis = rotation_helper.transform.basis.slerp(
        (target_rotation_helper_basis * bob_basis).orthonormalized(),
        mouse_rotation_friction * delta*mouse_rotation_speed*ROTATION_SLERP_FACTOR
    )

    target_cam_rot = Vector3.ZERO
    cam_rot_spd = Vector3.ZERO
