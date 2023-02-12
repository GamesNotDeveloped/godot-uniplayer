extends UP_BaseAbility
class_name UP_Hunger

signal food_level_changed

@export_node_path("UP_Health") var health_path:NodePath = NodePath("")
@export_node_path("UP_KillableBehaviour") var killable_path:NodePath = NodePath("")

@export var max_food_level:float = 10.0
@export var food_level:float = max_food_level
@export var food_tick:float = 1.0:
    set(x):
        food_tick = x
        _timer.wait_time = x
@export var hunger_tick_value:float = 0.1
@export var health_tick_value:float = 0.5


var _timer = Timer.new()
var _health:UP_Health
var _killable:UP_KillableBehaviour

func _ready():
    super()
    _health = get_node(health_path)
    _killable = get_node(killable_path)
    
    if _health:
        _timer.one_shot = false
        _timer.timeout.connect(_on_food_tick)
        add_child(_timer)
        #self.active_toogled.connect(self._on_active_change)
        _timer.start()
    else:
        push_warning("Hunger requires UP_Health path set to operate")
    
    if _killable:
        _killable.respawned.connect(_reset)
    else:
        push_warning("Hunger requires UP_Killable path set to reset on respawn")
        
func _on_active_change():
    if active:
        _timer.start()
    else:
        _timer.stop()

func _on_food_tick():
    if food_level > 0:
        food_level = clampf(food_level - hunger_tick_value, 0.0, max_food_level)
        food_level_changed.emit()
    else:
        _health.change(-health_tick_value)

func _reset():
    food_level = max_food_level
    food_level_changed.emit()
