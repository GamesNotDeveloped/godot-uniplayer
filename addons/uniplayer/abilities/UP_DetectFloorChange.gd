extends UP_BaseAbility
class_name UP_DetectFloorChange

signal floor_changed(floor: Node3D)

@export_flags_3d_physics var collision_mask: int = 1

var ray:RayCast3D = RayCast3D.new()
var timer:Timer = Timer.new()
var previous_floor: Node3D

func _ready():
    ray.enabled = true
    ray.exclude_parent = true
    ray.target_position = Vector3(0, -0.5, 0)
    player.add_child.call_deferred(ray)
    ray.position = Vector3(0, 0.25, 0)
    ray.collide_with_bodies = true
    ray.collide_with_areas = true
    ray.collision_mask = collision_mask
    
    timer.wait_time = 0.05
    timer.connect("timeout", _update)
    timer.one_shot = false
    add_child(timer)
    timer.start()


func _update():
    if not active:
        return
    if ray.is_colliding():
        var c = ray.get_collider()
        if not previous_floor or not previous_floor == c:
            previous_floor = c
            prints("Detected floor", c)
            emit_signal("floor_changed", c)
    elif previous_floor:
        previous_floor = null
        print("No floor detected")
        emit_signal("floor_changed", null)
