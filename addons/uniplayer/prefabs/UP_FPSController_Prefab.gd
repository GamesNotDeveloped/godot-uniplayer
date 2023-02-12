extends UP_PlayerBase

signal footstep(leg: int)
signal floor_changed(floor: Node3D)
signal landed(velocity: Vector3)

@export_category("Features")
@export var bobbing_enabled:bool = true:
    set(x):
        bobbing_enabled = x
        $Bobbing.active = x

@export var zoom_enabled:bool = true:
    set(x):
        zoom_enabled = x
        $Zooming.active = x        

@export var kill_y_enabled:bool = true:
    set(x):
        kill_y_enabled = x
        $Kill_Y.active = x        
        
@export_category("Movement")
@export var always_run:bool = false:
    set(x):
        always_run = x
        $Walking.ALWAYS_RUN = x

@export_range(-5, 5) var gravity_factor:float = 1.0:
    set(x):
        gravity_factor = x
        $Walking.GRAVITY = _get_default("walking_gravity", $Walking.GRAVITY) * gravity_factor

@export_range(0.01, 10) var speed_factor:float = 1.0:
    set(x):
        speed_factor = x
        $Walking.WALK_SPEED = _get_default("walk_speed", $Walking.WALK_SPEED) * x
        $Walking.RUN_SPEED = _get_default("run_speed", $Walking.RUN_SPEED) * x
        $Walking.CROUCH_SPEED = _get_default("crouch_speed", $Walking.CROUCH_SPEED) * x

@export_range(0.01, 1) var hurry_factor:float = 0.5:
    set(x):
        hurry_factor = x
        var def_walk = _get_default("walk_speed", $Walking.WALK_SPEED)
        
        $Walking.WALK_SPEED = def_walk + ($Walking.RUN_SPEED-def_walk)*x

@export_range(0.01, 10) var footstep_time_factor:float = 1.0:
    set(x):
        footstep_time_factor = x
        $Walking.walk_footstep_time_factor = _get_default("walk_footstep_time_factor", $Walking.walk_footstep_time_factor) * x
        $Walking.run_footstep_time_factor = _get_default("run_footstep_time_factor", $Walking.run_footstep_time_factor) * x
        $Walking.crouch_footstep_time_factor = _get_default("crouch_footstep_time_factor", $Walking.crouch_footstep_time_factor) * x

@export_category("Health & Damage")
@export var max_health:float = 10.0:
    set(x):
        max_health = x
        $Health.max_health = x
        
@export var immortal:bool = false:
    set(x):
        immortal = x
        $Killable.active = not x
        $Kill_Y.active = not x
@export var respawn_type:UP_KillableBehaviour.RespawnType = UP_KillableBehaviour.RespawnType.RespawnLastGood:
    set(x):
        respawn_type = x
        $Killable.respawn_type = x

@export_category("Visuals")
@export_range(0.0, 10.0) var bob_strength_factor:float = 1.0:
    set(x):
        bob_strength_factor = x
        $Walking.BOB_STRENGTH = bob_strength_factor

@export_range(0.01, 10.0) var player_scale:float = 1.0:
    set(x):
        player_scale = x
        $CollisionShape3D.shape.height = _get_default("collision_shape_height", $CollisionShape3D.shape.height) * x
        $CollisionShape3D.shape.radius = _get_default("collision_shape_radius", $CollisionShape3D.shape.radius) * x
        $CollisionShape3D.position.y = $CollisionShape3D.shape.height * 0.5
        $RotationHelper.position.y = _get_default("rotation_helper_position_y", $RotationHelper.position.y) * x

        
var _defaults = {}
func _get_default(key, default):
    if not _defaults.has(key):
        _defaults[key] = default
    return _defaults[key]


func _ready():
    $Walking.connect("footstep", func(leg): emit_signal("footstep", leg))
    $Walking.connect("land", func(vel): emit_signal("landed", vel))
    $DetectFloorChange.connect("floor_changed", func(floor): emit_signal("floor_changed", floor))
    
