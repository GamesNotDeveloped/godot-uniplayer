extends Control

@export_node_path("UP_Hunger") var hunger_path:NodePath = NodePath("")
var _hunger:UP_Hunger

func _ready():
    _hunger = get_node(hunger_path)
    if _hunger:
        _hunger.connect("food_level_changed", _update)
        $%ProgressBar.max_value = _hunger.max_food_level
        _update()

func _update():
    $%ProgressBar.value = _hunger.food_level
