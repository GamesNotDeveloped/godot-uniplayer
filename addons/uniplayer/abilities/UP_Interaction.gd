@tool

extends UP_BaseAbility
class_name UP_Interaction

signal target_changed(target: Node3D)
signal pressed(target: Node3D)
signal released(target: Node3D)


@export var interaction_range = 3.0:
    set(x):
        interaction_range = x
        _dirty = true
@export var interaction_shape_radius = 0.1:
    set(x):
        interaction_shape_radius = x
        _dirty = true
        
@export var ray_check_interval = 0.05
@export_flags_3d_physics var collision_mask:int = 1
@export_node_path("Camera3D") var camera_path:NodePath = NodePath(""):
    set(x):
        camera_path = x
        _dirty = true

@export_subgroup("Actions")
@export var ACTION_OPERATE = "operate"

var ray = ShapeCast3D.new()
var camera:Camera3D

var _interactive_target:Node3D

var _t:float = 0
var _dirty = false

var DEFAULT_ACTIONS = [
    [ACTION_OPERATE, null, MOUSE_BUTTON_LEFT],
]

func _ready():
    super()
    _update_ray()
    if not Engine.is_editor_hint():
        player.register_default_input_bindings(DEFAULT_ACTIONS)    
    if not camera:
        push_warning(self, ": camera is not set. Ability to interaction will not work.")
        
func _process(delta):    
    if not camera:
        return
    if Engine.is_editor_hint():
        if _dirty:
            _dirty = false
            _update_ray()        

    if _interactive_target:
        if Input.is_action_just_pressed(ACTION_OPERATE):
            pressed.emit(_interactive_target)
        elif Input.is_action_just_released(ACTION_OPERATE):
            released.emit(_interactive_target)
                    
    _t -= delta
    if _t < 0:
        _t = ray_check_interval
        _update()


func _update_ray():
    camera = get_node(camera_path)
    
    if camera:
        if ray.get_parent():
           ray.get_parent().remove_child(ray)
         
        
        ray.collision_mask = collision_mask
        ray.collide_with_areas = true
        ray.collide_with_bodies = false
        ray.max_results = 1
        ray.target_position = Vector3(0, 0, -interaction_range)
        ray.enabled = true
        ray.rotation = Vector3(0.5 * PI, 0, 0)
        ray.position = Vector3(0, 0, -interaction_range * 0.5)        
        
        var cyl:CylinderShape3D = CylinderShape3D.new()
        cyl.radius = interaction_shape_radius
        cyl.height = interaction_range
        ray.visible = true
        ray.shape = cyl
        
        camera.add_child(ray)

    
func _update():
    if ray.is_colliding():
        var target = ray.get_collider(0)
        if not _interactive_target == target:
            _interactive_target = target
            target_changed.emit(_interactive_target)
    elif _interactive_target:
        _interactive_target = null
        target_changed.emit(null)
