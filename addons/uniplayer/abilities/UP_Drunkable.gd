extends UP_BaseAbility
class_name UP_Drunkable

@export_range(0, 1) var drunkeness = 0.0
@export_node_path("UP_RotationHelper") var rotation_helper_path:NodePath = NodePath("")
@export_node_path("Camera3D") var camera_path:NodePath = NodePath("")

var rh:UP_RotationHelper
var cam:Camera3D
var target_rh_basis = Basis()
var _t = 0.0
var _t2 = 0.0
var _camattrs:CameraAttributesPractical

func _ready():
    player.register_movement_ability(self)
    rh = get_node(rotation_helper_path)
    cam = get_node(camera_path) as Camera3D
    if cam:
        _camattrs = CameraAttributesPractical.new()
        _camattrs.dof_blur_far_enabled = false
        _camattrs.dof_blur_far_distance = 0
        cam.attributes = _camattrs


func _process_movement(delta):
    if drunkeness > 0.0:
        player.velocity += Vector3(
            randf_range(-2.0, 2.0), 0, randf_range(-2.0, 2.0)
        ) * drunkeness * (player.velocity.length()*0.1)

        player.velocity += Vector3((sin(_t2) * 0.5 * drunkeness), 0, 0)

        _t += delta
        _t2 = wrapf(_t2 + delta, 0, TAU)

        if _t > 0.1:
            target_rh_basis = rh.basis.rotated(
                Vector3.LEFT, randf_range(-5.0, 5.0) * drunkeness
            ).rotated(
                Vector3.FORWARD, randf_range(-2.0, 2.0)*drunkeness
            )
            _t = 0.0

        rh.basis = rh.basis.slerp(target_rh_basis, delta * 0.2)

        if _camattrs:
            if not _camattrs.dof_blur_far_enabled:
                _camattrs.dof_blur_far_enabled = true
            var blurriness = 0.2 * drunkeness * sin(wrapf(_t2, 0, PI))
            _camattrs.dof_blur_amount = blurriness
    else:
        if _camattrs and _camattrs.dof_blur_far_enabled:
            _camattrs.dof_blur_far_enabled = false
