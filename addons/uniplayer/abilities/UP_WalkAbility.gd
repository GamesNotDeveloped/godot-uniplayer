extends UP_BaseAbility
class_name UP_WalkAbility

# Responsibility:
# - walking, running, jumping, crouching of the player character

signal footstep
signal jump
signal land(velocity:Vector3)
signal falling

@export_node_path("UP_RotationHelper") var rotation_helper_path:NodePath = NodePath()
@export_node_path("UP_Bobbing") var bobbing_path:NodePath = NodePath()

@export var GRAVITY = -9.8
@export var WALK_SPEED = 2.0
@export var RUN_SPEED = 4.0
@export var CROUCH_SPEED = 0.5
@export var ALWAYS_RUN:bool = false

@export_subgroup("Movement")

@export_range(0.01, 1.0) var ACCEL = 0.8
@export_range(0.01, 1.0) var FRICTION = 0.2
@export var FALL_INJURY_VELOCITY = -5.0
@export var FALL_INJURY_MIN_LENGTH = 5.0
@export var JUMP_SPEED = 4.0
@export var JUMP_SPEED_RUN = 5.0
@export var jump_in_air:bool = false
@export var max_jumps_in_air:int = 0

@export_subgroup("Footsteps")
@export var NUM_LEGS:int = 2
@export var walk_footstep_time_factor:float = 1.5
@export var run_footstep_time_factor:float = 1.2
@export var crouch_footstep_time_factor:float = 4.0

@export_subgroup("Bobbing")
@export_range(0.0, 10.0) var BOB_STRENGTH = 1.0
@export_range(0.0, 10.0) var BOB_WALK_STRENGTH = 0.3
@export_range(0.0, 10.0) var BOB_RUN_STRENGTH = 0.8
@export_range(0.0, 10.0) var BOB_CROUCH_STRENGTH = 0.1
@export_range(0.0, 100.0) var BOB_STAY_SHAKINESS = 1.1
@export_range(0.0, 100.0) var BOB_STAY_FACTOR = 2.0
@export_range(0.0, 1.0) var BOB_WALK_ROT_FACTOR = 0.2
@export_range(0.0, 1.0) var BOB_WALK_POS_FACTOR = 0.5
@export_range(0.0, 1.0) var BOB_CROUCH_FACTOR = 0.5
@export_subgroup("Camera")
@export var crouch_camera_height_factor = 0.6
@export_range(0.001, 10.0) var crouch_camera_speed_factor = 2.5


@export_subgroup("Keys")
@export var ACTION_LEFT = "left"
@export var ACTION_RIGHT = "right"
@export var ACTION_FORWARD = "forward"
@export var ACTION_BACKWARD = "backward"
@export var ACTION_JUMP = "jump"
@export var ACTION_CROUCH = "crouch"
@export var ACTION_RUN = "run"


var last_input_movement = Vector2.ZERO
var dir = Vector3()
var dir_raw = Vector3()
var jumped = false
var _crouch = false
var on_floor = false
var is_falling = false
var in_water = false
var _footstep_val = 0
var _footstep_leg = 0
var _was_footstep = false
var footstep_time_factor:float = walk_footstep_time_factor

var _falling_start_y:float = 0.0
var _falling_velocity:float = 0.0
var _is_running = false
var rotation_helper:Node3D
var rotation_helper_original_y:float = 0.0
var _target_rotation_helper_y:float = 0.0
var _resetting = false
var _fall_rot = 0.0

var bobbing:UP_Bobbing
var _bob_stay = 0.0
var _bob_stay_factor = 1.0
var _bob_stay_shakiness:float = 0.0
var _bob_jumped = false
    
var _land_foot_timer = Timer.new()
var _land_foot_leg:int = NUM_LEGS

func _set_crouch(state: bool):
    _crouch = state
    if rotation_helper:
        if _crouch:
            _target_rotation_helper_y = rotation_helper.position.y * crouch_camera_height_factor
        else:
            _target_rotation_helper_y = rotation_helper_original_y

var DEFAULT_INPUT_BINDINGS = [
    [ACTION_LEFT, KEY_A, null],
    [ACTION_RIGHT, KEY_D, null],
    [ACTION_FORWARD, KEY_W, null],
    [ACTION_BACKWARD, KEY_S, null],
    [ACTION_JUMP, KEY_SPACE, null],
    [ACTION_CROUCH, KEY_CTRL, null],
    [ACTION_RUN, KEY_SHIFT, null],
]

func _ready():
    super()
    player.register_default_input_bindings(DEFAULT_INPUT_BINDINGS)
    player.register_control_ability(self)
    player.register_movement_ability(self)
    player.connect("reset", _reset)
    player.connect("controllable_changed", _stop_walking)
    
    _land_foot_timer.wait_time = 0.2
    _land_foot_timer.one_shot = true
    _land_foot_timer.connect("timeout", _on_land_foot_timer)
    add_child(_land_foot_timer)
    
    rotation_helper = get_node(rotation_helper_path)
    if rotation_helper:
        rotation_helper_original_y = rotation_helper.position.y
        _target_rotation_helper_y = rotation_helper.position.y
    bobbing = get_node(bobbing_path) as UP_Bobbing
    if bobbing:
        bobbing.register_bobbing(self)
        
func _process_control(delta):
    #if not active:
    #    return
    dir = Vector3.ZERO
    footstep_time_factor = crouch_footstep_time_factor if _crouch else (run_footstep_time_factor if _is_running else walk_footstep_time_factor)
    
    var _t = player.global_transform

    var input_movement_vector = Vector2()
    input_movement_vector.y += Input.get_action_strength(ACTION_FORWARD)-Input.get_action_strength(ACTION_BACKWARD)

    if Input.is_action_pressed(ACTION_LEFT):
        input_movement_vector.x -= 1

    if Input.is_action_pressed(ACTION_RIGHT):
        input_movement_vector.x += 1

    last_input_movement = input_movement_vector

    # Basis vectors are already normalized.
    dir_raw = Vector3(input_movement_vector.x, 0, input_movement_vector.y)
    dir += -_t.basis.z * input_movement_vector.y
    dir += _t.basis.x * input_movement_vector.x

    if Input.is_action_just_pressed(ACTION_JUMP):
        if on_floor or jump_in_air: # and not fly_mode):
            emit_signal("jump")
            jumped = true
            player.velocity.y = JUMP_SPEED_RUN if _is_running else JUMP_SPEED

    if Input.is_action_just_pressed(ACTION_CROUCH):
        _set_crouch(not _crouch)
    
    _is_running = Input.is_action_pressed(ACTION_RUN)
    _is_running = not _is_running if ALWAYS_RUN else _is_running
    

func _process_movement(delta):
    var velocity = player.velocity
    on_floor = player.is_on_floor()
    
    if on_floor:

        if is_falling:
            is_falling = false
            emit_signal("land", player.velocity) # FIMXE: should be contact velocity, not last known
            #emit_signal("footstep", 0)
            #if dir_raw == Vector3.ZERO:
            #    _land_foot_leg = NUM_LEGS
            #    _land_foot_timer.wait_time = randf_range(0.05, 0.15)
            #    _land_foot_timer.start()
            
            _footstep_val = 0
            
            #var _height_diff = _falling_start_y-player.global_transform.origin.y
            #if _height_diff > FALL_INJURY_MIN_LENGTH and _falling_velocity < FALL_INJURY_VELOCITY:
            #    var _factor1 = clamp(abs(_falling_velocity), 0, abs(GRAVITY))/abs(GRAVITY)
            #    var _factor2 = clamp(_height_diff-shape_height, 0, FALL_INJURY_MIN_LENGTH*3)/(FALL_INJURY_MIN_LENGTH*3)
            #    var _factor = clamp(_factor1*0.3+_factor2*0.7, 0.01, 1.0)
            #    var _log_factor = (2+log(_factor)) * 0.6 * (1.0/shape_height)

            #    hit_vel += Vector3((3.0-randf_range(1.0, 6.0))*20.0*_log_factor, 0, (3.0-randf_range(1.0, 6.0))*20.0*_log_factor)
            #    target_bob_pos_offset.y -= 10*_log_factor

            #    target_bob_rot_basis = target_bob_rot_basis.rotated(Vector3.FORWARD, 0.5*PI-PI*_log_factor).rotated(Vector3.LEFT, 0.2*PI*_log_factor)

            #    emit_signal("fall_damage", hit_vel)  # must be before hit calc to properly handle is_alive flag
            #    player.do_hit(max_health*0.3*_factor, 4.0 * _log_factor, 0.2)    
        if not dir == Vector3.ZERO:
            var _max = CROUCH_SPEED if _crouch else (RUN_SPEED if _is_running else WALK_SPEED)
            velocity.x = lerp(velocity.x, dir.x * _max, 10*ACCEL*delta)
            velocity.z = lerp(velocity.z, dir.z * _max, 10*ACCEL*delta)
        else:
            if abs(velocity.x) > 0.05:
                velocity.x = lerp(velocity.x, 0.0, FRICTION)
            else:
                velocity.x = 0.0
            if abs(velocity.z) > 0.05:
                velocity.z = lerp(velocity.z, 0.0, FRICTION)
            else:
                velocity.z = 0.0
            var _velxz = Vector3(velocity.x, 0, velocity.z) * dir.normalized()
            if _velxz.length() < 0.001:
                _footstep_val = 0.0
        
        #_footstep_val = wrapf(_footstep_val + abs(velocity.length()) * delta * footstep_time_factor, 0, 3)
        var _foot_vel = velocity.length()
        _footstep_val = wrapf(_footstep_val + 2 * _foot_vel * delta * footstep_time_factor, 0, 6)
        if fposmod(_footstep_val, 3.0) > 2 and not _was_footstep:
            _was_footstep = true
            emit_signal("footstep", _footstep_leg)
            _footstep_leg = wrapi(_footstep_leg+1, 0, NUM_LEGS)
        elif fposmod(_footstep_val, 3.0) < 2 and _was_footstep:
            _was_footstep = false
    else:
        if not is_falling:
            is_falling = true
            #$FloorCheckTimer.wait_time = 0.1
            _falling_velocity = 0.0
            _falling_start_y = player.global_transform.origin.y
            emit_signal("falling")
        else:
            _falling_velocity = min(_falling_velocity, velocity.y)
            if not player.controllable and rotation_helper:
                _fall_rot = clampf(_fall_rot+delta*1.0, 0.0, PI*0.5)
                rotation_helper.basis = rotation_helper.basis.slerp(
                    rotation_helper.basis.rotated(Vector3.LEFT, _fall_rot),
                    delta * 0.5
                )
                
        #if not is_alive:
        #    rotate_x(_kill_rot.x * delta * 2.0)
        #    rotate_y(_kill_rot.y * delta * 2.0)
        #    rotate_z(_kill_rot.z * delta * 2.0)
    #velocity += hit_vel
    
    #if in_water:
    #    velocity.y += (GRAVITY_WATER + (GRAVITY*(1-WATER_FRICTION)*0.3)) * delta
    #else:
    #    velocity.y += GRAVITY * delta

    velocity.y += GRAVITY * delta
    player.velocity = velocity

    if rotation_helper:
        rotation_helper.position.y = lerp(
            rotation_helper.position.y,
            _target_rotation_helper_y,
            delta * crouch_camera_speed_factor * 4.0
        )
    if jumped:
        jumped = false
        _bob_jumped = true

func _reset():
    _set_crouch(false)
    dir = Vector3.ZERO
    dir_raw = Vector3.ZERO 
    last_input_movement = Vector2.ZERO
    jumped = false
    on_floor = false
    is_falling = false
    in_water = false
    _footstep_val = 0
    _footstep_leg = 0
    _was_footstep = false
    _falling_start_y = 0.0 
    _falling_velocity = 0.0
    _target_rotation_helper_y = rotation_helper_original_y
    if rotation_helper:
        rotation_helper.position.y = rotation_helper_original_y


func _stop_walking():
    dir = Vector3.ZERO
    dir_raw = Vector3.ZERO


func _process_bobbing(delta):
    #var velocity_length = player.velocity.length()
    #var velocity_length = 0.0 if player.velocity.is_zero_approx() else 1.0
    var velocity_length = clamp(player.velocity.length(), 0, 1.0)
    var inv_velocity_factor = 1.0-clampf(velocity_length, 0, 1.0)
    
    # add subtle bob when staying
    
    _bob_stay = wrapf(_bob_stay + delta * 2.0, 0.0, TAU)
    bobbing.add_bobbing(
        Transform3D(
            Basis(),
            Vector3(
                sin(_bob_stay)+randf_range(-1, 1)*BOB_STAY_SHAKINESS,
                cos(_bob_stay) * 0.5,
                0
            ) * 0.01 * BOB_STAY_FACTOR * inv_velocity_factor
        )
    )
    
    # add walk bobing
    var _bob_val = _footstep_val  # match footsteps
    #var x_velocity = 0
    if on_floor:
        var current_bob_transform = bobbing.get_bobbing()
        #var spd = RUN_SPEED if _is_running else WALK_SPEED

        #x_velocity = (player.velocity * player.global_transform.basis).x/spd 

        if velocity_length > 0.2:
            _bob_val = fposmod(_bob_val + 1.5, 6.0)  # offset 1/2
            var _walk_rot = sin( PI*(_bob_val/3.0))
            var crouch_factor = BOB_CROUCH_FACTOR if _crouch else 1.0

            current_bob_transform.basis = (
                current_bob_transform.basis.rotated(
                    Vector3.FORWARD, PI * _walk_rot * 0.1 * BOB_WALK_ROT_FACTOR
                )
            )
            current_bob_transform.origin = Vector3(
                _walk_rot * 2.0 * BOB_WALK_POS_FACTOR,
                sin(TAU*(_bob_val/3.0)) * 2.0 * BOB_WALK_POS_FACTOR * crouch_factor,
                0.0
            )
#        else:
#            _bob_val = lerp(_bob_val, 0.0, delta * BOB_STABILIZE_SPEED)



        #var overall_factor = BOB_STRENGTH * (
        #    BOB_CROUCH_STRENGTH if _crouch else (
        #        BOB_RUN_STRENGTH if _is_running and velocity_length > 0.5 else BOB_WALK_STRENGTH
        #    )
        #)
        
        var overall_factor = BOB_STRENGTH * BOB_RUN_STRENGTH * velocity_length
        
        current_bob_transform.origin *= overall_factor
        
        
        if _bob_jumped:
            _bob_jumped = false
            current_bob_transform.origin.y -= JUMP_SPEED * 0.2
            current_bob_transform.basis = current_bob_transform.basis.rotated(
                Vector3.FORWARD, 2.0*PI*(1.0-randf_range(0.0, 2.0))
            )

        bobbing.replace_bobbing(current_bob_transform)

func _on_land_foot_timer():

    if _land_foot_leg > 0 and not dir_raw == Vector3.ZERO:
        _land_foot_leg -= 1
        emit_signal("footstep", _land_foot_leg)
        _land_foot_timer.wait_time = randf_range(0.05, 0.15)
        _land_foot_timer.start()
        
